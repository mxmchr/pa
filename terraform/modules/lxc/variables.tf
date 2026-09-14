############################################
### Identité                              ###
############################################

variable "description" {
  description = "Description du conteneur."
  type        = string
  default     = "Managed by Terraform"
}

variable "node_name" {
  description = "Nœud Proxmox sur lequel créer le conteneur."
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
  description = "Pool de ressources Proxmox auquel rattacher le conteneur."
  type        = string
}

variable "tags" {
  description = "Tags Proxmox appliqués au conteneur."
  type        = list(string)
  default     = []
}

variable "hostname" {
  description = "Hostname du conteneur."
  type        = string
}

############################################
### Ressources                            ###
############################################

variable "architecture" {
  description = "Architecture processeur du conteneur."
  type        = string
  default     = "amd64"
}

variable "cores" {
  description = "Nombre de cœurs alloués."
  type        = number
  default     = 1
}

variable "units" {
  description = "Poids relatif du conteneur dans l'ordonnancement CPU."
  type        = number
  default     = 1024
}

variable "memory_size" {
  description = "Mémoire allouée (Mo)."
  type        = number
  default     = 512
}

variable "swap_size" {
  description = "Espace d'échange alloué (Mo)."
  type        = number
  default     = 512
}

variable "nesting" {
  description = <<-EOT
    Autorise le nesting dans le conteneur. Activé par défaut : Proxmox émet
    un avertissement sur les invités en systemd 257 lorsqu'il est absent.

    Écart au §8.4 du dossier, qui annonce des conteneurs durcis.
  EOT
  type        = bool
  default     = true
}

############################################
### Réseau                                ###
############################################

variable "network_interface_name" {
  description = "Nom de l'interface réseau vue depuis le conteneur."
  type        = string
  default     = "eth0"
}

variable "network_bridge" {
  description = "Bridge Proxmox, c'est-à-dire le VNet SDN du segment."
  type        = string
}

variable "mac_address" {
  description = "Adresse MAC imposée. null pour laisser Proxmox l'attribuer."
  type        = string
  default     = null

  validation {
    condition     = var.mac_address == null || can(regex("^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$", var.mac_address))
    error_message = "mac_address doit être null ou au format XX:XX:XX:XX:XX:XX."
  }
}

variable "ipv4_address" {
  description = "Adresse IPv4 : \"dhcp\" ou CIDR."
  type        = string
  default     = "dhcp"

  validation {
    condition     = can(regex("^(dhcp|\\d{1,3}(?:\\.\\d{1,3}){3}/\\d{1,2})$", var.ipv4_address))
    error_message = "ipv4_address doit être 'dhcp' ou au format CIDR, ex: 10.0.20.5/24."
  }
}

variable "ipv4_gateway" {
  description = "Passerelle IPv4. null si DHCP."
  type        = string
  default     = null

  validation {
    condition     = var.ipv4_gateway == null || can(regex("^\\d{1,3}(?:\\.\\d{1,3}){3}$", var.ipv4_gateway))
    error_message = "ipv4_gateway doit être null ou une IPv4 au format x.x.x.x."
  }
}

variable "dns_domain" {
  description = "Domaine de recherche."
  type        = string
  default     = "pa.lan"
}

variable "dns_servers" {
  description = "Résolveurs."
  type        = list(string)
  default     = null
}

variable "wait_for_ip" {
  description = <<-EOT
    Attendre l'obtention d'une IPv4 à la création. Sans effet si
    ipv4_address n'est pas "dhcp". Laissé à false tant qu'aucun service
    d'attribution d'adresses n'est déployé sur les segments.
  EOT
  type        = bool
  default     = false
}

############################################
### Stockage                              ###
############################################

variable "datastore_id" {
  description = <<-EOT
    Stockage du disque système. Sans défaut volontairement : un stockage
    local interdit la migration, donc la mise sous gestion HA. La valeur
    partagée est résolue par le root module (var.shared_datastore_id).
  EOT
  type        = string
}

variable "disk_size" {
  description = "Taille du disque système (Go)."
  type        = number
  default     = 4

  validation {
    condition     = var.disk_size >= 1
    error_message = "disk_size doit être >= 1 (Go)."
  }
}

variable "mount_points" {
  description = "Points de montage additionnels."
  type = list(object({
    volume = string
    path   = string
    size   = optional(string)
  }))
  default = []
}

############################################
### Template                              ###
############################################

variable "os_type" {
  description = "Type d'OS attendu par le provider."
  type        = string
  default     = "debian"
}

variable "template_file_id" {
  description = <<-EOT
    Identifiant d'un template existant, par exemple
    "local:vztmpl/debian-13-standard_13.x-y_amd64.tar.zst". Si null, le
    module télécharge template_url.
  EOT
  type        = string
  default     = null
}

variable "template_url" {
  description = "URL du template à télécharger. Requis si template_file_id est null."
  type        = string
  default     = null
}

variable "template_datastore" {
  description = <<-EOT
    Stockage du template téléchargé. Doit accepter le content type vztmpl,
    ce qu'un stockage RBD ne fait pas : rester sur local. Attention, "local"
    n'est pas partagé entre les nœuds.
  EOT
  type        = string
  default     = "local"
}

############################################
### Accès                                 ###
############################################

variable "extra_ssh_keys" {
  description = <<-EOT
    Clés publiques supplémentaires, en plus de celle générée pour ce
    workload. C'est par l'une d'elles qu'Ansible se connecte : sans clé
    commune, il faudrait extraire du state une clé privée par hôte.

    Proxmox n'écrit authorized_keys qu'à la création du conteneur : modifier
    cette liste impose une recréation.
  EOT
  type        = list(string)
  default     = []
}

variable "root_password_length" {
  description = "Longueur du mot de passe généré pour root."
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
    Délai d'attente de la création, en secondes. L'extraction d'un template
    vers Ceph dépasse largement le défaut du provider sur la maquette, où
    les trois nœuds sont virtualisés et partagent le même disque physique.
  EOT
  type        = number
  default     = 5400
}

variable "timeout_delete" {
  description = "Délai d'attente de la suppression, en secondes."
  type        = number
  default     = 3600
}

############################################
### Valeurs dérivées                      ###
############################################

locals {
  unprivileged       = true
  protection_enabled = false

  wait_for_ipv4 = var.wait_for_ip && var.ipv4_address == "dhcp"

  template_id = coalesce(
    var.template_file_id,
    try(proxmox_virtual_environment_download_file.this[0].id, null),
  )
}

check "template_source" {
  assert {
    condition     = var.template_file_id != null || var.template_url != null
    error_message = "Renseigner template_file_id (template existant) ou template_url (téléchargement)."
  }
}