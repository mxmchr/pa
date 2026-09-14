############################################
### Identité                              ###
############################################

variable "name" {
  description = "Nom de la VM dans Proxmox."
  type        = string
}

variable "node_name" {
  description = "Nœud Proxmox sur lequel créer la VM."
  type        = string
}

variable "vm_id" {
  description = <<-EOT
    VMID Proxmox, obligatoire. Un identifiant attribué automatiquement
    varierait d'un déploiement à l'autre et rendrait non reproductible le
    rattachement HA. Plan : docs/architecture/plan-vmid.md
  EOT
  type        = number
}

variable "pool_id" {
  description = "Pool de ressources Proxmox auquel rattacher la VM."
  type        = string
}

variable "tags" {
  description = "Tags Proxmox appliqués à la VM."
  type        = list(string)
  default     = []
}

############################################
### Source du disque                      ###
############################################

variable "disk_import_from" {
  description = <<-EOT
    Identifiant d'une image à importer comme disque système, typiquement une
    ressource proxmox_virtual_environment_download_file de content_type
    "import". Exclusif avec disk_file_id.

    L'image est copiée dans le stockage de la VM : contrairement à un clone
    lié, l'opération duplique les données.
  EOT
  type        = string
  default     = null
}

variable "disk_file_id" {
  description = <<-EOT
    Identifiant d'une image disque brute à attacher, pour les appliances
    livrées sous cette forme. Exclusif avec disk_import_from.
  EOT
  type        = string
  default     = null
}

variable "cdrom_file_id" {
  description = "Image ISO montée en lecteur optique. null pour aucun."
  type        = string
  default     = null
}

variable "datastore_id" {
  description = <<-EOT
    Stockage du disque système. Sans défaut volontairement : un stockage
    local interdit la migration, donc la mise sous gestion HA. La valeur
    partagée est résolue par le root module (var.shared_datastore_id).
  EOT
  type        = string
}

variable "disk_size" {
  description = "Taille du disque système (Go). Doit être >= à celle de l'image."
  type        = number
  default     = 8

  validation {
    condition     = var.disk_size >= 1
    error_message = "disk_size doit être >= 1 (Go)."
  }
}

############################################
### Matériel                              ###
############################################

variable "cores" {
  description = "Nombre de cœurs par socket."
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Nombre de sockets CPU."
  type        = number
  default     = 1
}

variable "cpu_type" {
  description = <<-EOT
    Modèle de CPU émulé. "host" expose le jeu d'instructions de l'hôte : les
    modèles synthétiques réclament cmp-legacy, une extension AMD que l'hôte de
    virtualisation imbriquée n'expose pas, et le démarrage échoue.

    Contrepartie : "host" empêche la migration vers un nœud de génération
    différente, à réévaluer avant la phase 08 sur du matériel hétérogène.
  EOT
  type        = string
  default     = "host"
}

variable "memory_size" {
  description = "Mémoire dédiée (Mo)."
  type        = number
  default     = 2048
}

variable "machine" {
  description = "Type de machine QEMU."
  type        = string
  default     = "q35"
}

variable "bios" {
  description = "Firmware : \"seabios\" ou \"ovmf\"."
  type        = string
  default     = "seabios"

  validation {
    condition     = contains(["seabios", "ovmf"], var.bios)
    error_message = "bios doit valoir \"seabios\" ou \"ovmf\"."
  }
}

variable "os_type" {
  description = "Type d'OS : \"l26\" pour Linux, \"other\" pour les systèmes BSD."
  type        = string
  default     = "l26"
}

variable "agent_enabled" {
  description = <<-EOT
    Active l'attente de l'agent invité. À laisser à false tant que
    qemu-guest-agent n'est pas installé dans l'invité : l'image cloud Debian
    ne l'embarque pas, et le provider attendrait jusqu'au délai d'expiration.
  EOT
  type        = bool
  default     = false
}

variable "keyboard_layout" {
  description = "Disposition clavier de la console."
  type        = string
  default     = "fr"
}

############################################
### Réseau                                ###
############################################

variable "network_devices" {
  description = <<-EOT
    Interfaces réseau, dans l'ordre : la première devient net0, la deuxième
    net1, etc.

    Attention : l'ordre des cartes côté Proxmox ne détermine pas celui des
    périphériques vus par l'invité, qui dépend de l'énumération PCI. Toute
    configuration qui doit désigner une carte précise s'appuie sur sa MAC,
    et non sur son rang.

    mtu : 1450 sur les segments SDN, l'encapsulation VXLAN coûtant 50 octets.
  EOT
  type = list(object({
    bridge      = string
    mac_address = optional(string, null)
    vlan_id     = optional(number, null)
    model       = optional(string, "virtio")
    firewall    = optional(bool, false)
    mtu         = optional(number, null)
  }))

  validation {
    condition     = length(var.network_devices) >= 1
    error_message = "Au moins une interface réseau est requise."
  }

  validation {
    condition = alltrue([
      for nic in var.network_devices :
      nic.mac_address == null || can(regex("^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$", nic.mac_address))
    ])
    error_message = "mac_address doit être null ou au format XX:XX:XX:XX:XX:XX."
  }
}

############################################
### Cloud-init                            ###
############################################

variable "cloud_init" {
  description = <<-EOT
    Active l'initialisation cloud-init. À désactiver pour une appliance qui
    porte sa propre configuration : le lecteur attaché serait ignoré.
  EOT
  type        = bool
  default     = true
}

variable "cloud_init_username" {
  description = <<-EOT
    Compte créé par cloud-init et porteur des clés. C'est ce compte que
    l'inventaire Ansible utilise comme ansible_user.
  EOT
  type        = string
  default     = "ansible"
}

variable "extra_ssh_keys" {
  description = <<-EOT
    Clés publiques supplémentaires, en plus de celle générée pour ce workload.
    C'est par l'une d'elles qu'Ansible se connecte.
  EOT
  type        = list(string)
  default     = []
}

variable "dns_domain" {
  description = "Domaine de recherche injecté par cloud-init."
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "Résolveurs injectés par cloud-init."
  type        = list(string)
  default     = null
}

variable "ipv4_address" {
  description = "Adresse de la première interface : \"dhcp\" ou CIDR."
  type        = string
  default     = "dhcp"

  validation {
    condition     = can(regex("^(dhcp|\\d{1,3}(?:\\.\\d{1,3}){3}/\\d{1,2})$", var.ipv4_address))
    error_message = "ipv4_address doit être 'dhcp' ou au format CIDR."
  }
}

variable "ipv4_gateway" {
  description = "Passerelle de la première interface. null si DHCP."
  type        = string
  default     = null

  validation {
    condition     = var.ipv4_gateway == null || can(regex("^\\d{1,3}(?:\\.\\d{1,3}){3}$", var.ipv4_gateway))
    error_message = "ipv4_gateway doit être null ou une IPv4."
  }
}

variable "root_password_length" {
  description = "Longueur du mot de passe généré pour le compte cloud-init."
  type        = number
  default     = 20

  validation {
    condition     = var.root_password_length >= 20
    error_message = "root_password_length doit être >= 20."
  }
}

############################################
### Démarrage et délais                   ###
############################################

variable "on_boot" {
  description = "Démarrage automatique avec le nœud."
  type        = bool
  default     = true
}

variable "startup_order" {
  description = "Ordre de démarrage Proxmox."
  type        = number
  default     = 3
}

variable "startup_up_delay" {
  description = "Délai (secondes) avant de démarrer après son tour."
  type        = number
  default     = 0
}

variable "startup_down_delay" {
  description = "Délai (secondes) avant d'arrêter."
  type        = number
  default     = 0
}

variable "timeout_create" {
  description = <<-EOT
    Délai d'attente de la création, en secondes. L'importation d'une image
    copie plusieurs centaines de mégaoctets vers Ceph, ce qui dépasse
    largement le défaut du provider sur la maquette.
  EOT
  type        = number
  default     = 5400
}

variable "timeout_stop_vm" {
  description = "Délai d'attente de l'arrêt, en secondes."
  type        = number
  default     = 1800
}

variable "timeout_shutdown_vm" {
  description = "Délai d'attente de l'extinction, en secondes."
  type        = number
  default     = 1800
}

############################################
### Cohérence                             ###
############################################

check "disk_source" {
  assert {
    condition     = (var.disk_import_from == null) != (var.disk_file_id == null)
    error_message = "Renseigner disk_import_from OU disk_file_id, pas les deux ni aucun."
  }
}

check "cloud_init_fields" {
  assert {
    condition     = !var.cloud_init || var.ipv4_address != null
    error_message = "ipv4_address est requis lorsque cloud_init est actif."
  }
}