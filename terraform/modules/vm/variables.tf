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
    rattachement HA, qui lit ces identifiants dans le state.
    Plan d'attribution : docs/architecture/plan-vmid.md
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

variable "clone_vm_id" {
  description = <<-EOT
    VMID du template cloud-init à cloner. Exclusif avec disk_file_id.
    Le template doit préexister (rôle Ansible pve_vm_template).
  EOT
  type        = number
  default     = null
}

variable "disk_file_id" {
  description = <<-EOT
    Identifiant Proxmox d'une image disque à importer, par exemple
    "local:iso/OPNsense-25.1-amd64.img". Exclusif avec clone_vm_id.

    Destiné aux appliances livrées sous forme d'image, qui ne se clonent
    pas depuis un template cloud-init.
  EOT
  type        = string
  default     = null
}

variable "cdrom_file_id" {
  description = <<-EOT
    Identifiant d'une image ISO montée en lecteur optique, utilisée pour
    injecter une configuration d'amorçage à une appliance.
    Cf. docs/decisions/opnsense-bootstrap.md
  EOT
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
  description = "Taille du disque système (Go). Doit être >= à celle de la source."
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
  description = "Type de CPU émulé."
  type        = string
  default     = "x86-64-v2-AES"
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
  description = <<-EOT
    Type d'OS déclaré à Proxmox : "l26" pour Linux, "other" pour les
    systèmes BSD, dont OPNsense.
  EOT
  type        = string
  default     = "l26"
}

variable "agent_enabled" {
  description = <<-EOT
    Active l'attente de l'agent invité. À laisser à false tant que l'agent
    n'est pas installé dans l'invité : Terraform attendrait sinon un agent
    qui ne répond jamais, jusqu'au timeout.
  EOT
  type        = bool
  default     = true
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
    Interfaces réseau, dans l'ordre : la première devient net0, la
    deuxième net1, etc. L'ordre est significatif et ne doit pas changer
    sur une VM existante, sous peine de réattribuer les interfaces côté
    invité.

    Une VM ordinaire n'en déclare qu'une. Le pare-feu inter-zone en porte
    une par segment, plus l'interface externe.

    vlan_id reste null avec les VNets SDN, le tag étant porté par le VNet
    lui-même.
  EOT
  type = list(object({
    bridge      = string
    mac_address = optional(string, null)
    vlan_id     = optional(number, null)
    model       = optional(string, "virtio")
    firewall    = optional(bool, false)
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
    Active l'initialisation cloud-init : lecteur dédié, hostname, DNS,
    adressage de la première interface, clé et mot de passe générés.

    À désactiver pour une appliance qui porte sa propre configuration
    (OPNsense) : le lecteur attaché serait ignoré par l'invité, et les
    identifiants générés n'auraient aucun effet.
  EOT
  type        = bool
  default     = true
}

variable "hostname" {
  description = "Hostname injecté par cloud-init. Sans objet si cloud_init vaut false."
  type        = string
  default     = null
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
  description = "Adresse de la première interface (cloud-init) : \"dhcp\" ou CIDR."
  type        = string
  default     = "dhcp"

  validation {
    condition     = can(regex("^(dhcp|\\d{1,3}(?:\\.\\d{1,3}){3}/\\d{1,2})$", var.ipv4_address))
    error_message = "ipv4_address doit être 'dhcp' ou au format CIDR, ex: 10.0.20.10/24."
  }
}

variable "ipv4_gateway" {
  description = "Passerelle de la première interface (cloud-init). null si DHCP."
  type        = string
  default     = null

  validation {
    condition     = var.ipv4_gateway == null || can(regex("^\\d{1,3}(?:\\.\\d{1,3}){3}$", var.ipv4_gateway))
    error_message = "ipv4_gateway doit être null ou une IPv4 au format x.x.x.x."
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
### Démarrage                             ###
############################################

variable "on_boot" {
  description = "Démarrage automatique avec le nœud."
  type        = bool
  default     = true
}

variable "startup_order" {
  description = <<-EOT
    Ordre de démarrage Proxmox. Le pare-feu inter-zone porte les
    passerelles de tous les segments : il démarre en premier (1).
  EOT
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

############################################
### Cohérence                             ###
############################################

check "disk_source" {
  assert {
    condition     = (var.clone_vm_id == null) != (var.disk_file_id == null)
    error_message = "Renseigner clone_vm_id OU disk_file_id, pas les deux ni aucun."
  }
}

check "cloud_init_fields" {
  assert {
    condition     = !var.cloud_init || var.hostname != null
    error_message = "hostname est requis lorsque cloud_init est actif."
  }
}