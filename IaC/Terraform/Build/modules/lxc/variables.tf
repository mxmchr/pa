variable "description" {
  description = "Description du conteneur."
  type        = string
  default     = "Managed by Terraform"
}

variable "node_name" {
  description = "Nom du noeud Proxmox sur lequel créer le conteneur."
  type        = string
}

variable "vm_id" {
  description = "VMID Proxmox."
  type        = number
}

variable "pool_id" {
  description = "Pool ID"
  type = string
}

variable "hostname" {
  description = "Hostname du conteneur."
  type        = string
}

variable "dns_domain" {
  description = "Search domain"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers list"
  type        = list(string)
}

variable "architecture" {
  description = "CPU architecureture for the container."
  type        = string
  default     = "amd64"
}

variable "cores" {
  description = "Numbers of CPU cores allocated to the container."
  type        = number
  default     = 1
}

variable "units" {
  description = "CPU Units allocated to the container."
  type        = number
  default     = 1024
}

variable "memory_size" {
  description = "Taille de la mémoire RAM allouée au conteneur (en Mo)."
  type        = number
  default     = 512
}

variable "swap_size" {
  description = "Taille de la swap allouée au conteneur (en Mo)."
  type        = number
  default     = 512
}

variable "nesting" {
  description = "Autorise le nesting dans le conteneur."
  type        = bool
  default     = true
}

variable "network_interface_name" {
  description = "Nom de l'interface réseau côté conteneur."
  type        = string
  default     = "SRV"
}

variable "network_bridge" {
  description = "Bridge Proxmox (ex: vmbr0, vmbr105)."
  type        = string
  default     = "vmbr0"
}

variable "mac_address" {
  description = "Interface MAC address."
  type        = string
  default     = null

  validation {
    condition     = var.mac_address == null || can(regex("^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$", var.mac_address))
    error_message = "mac_address doit être null ou au format XX:XX:XX:XX:XX:XX."
  }
}

variable "ipv4_address" {
  description = "Adresse IPv4 (ex: 'dhcp' ou '192.168.1.10/24')."
  type        = string
  default     = "dhcp"

  validation {
    condition     = can(regex("^(dhcp|\\d{1,3}(?:\\.\\d{1,3}){3}/\\d{1,2})$", var.ipv4_address))
    error_message = "ipv4_address doit être 'dhcp' ou au format CIDR, ex: 192.168.1.10/24."
  }
}

variable "ipv4_gateway" {
  description = "Passerelle IPv4 (ex: 192.168.1.1). Laisser null si DHCP."
  type        = string
  default     = null

  validation {
    condition     = var.ipv4_gateway == null || can(regex("^\\d{1,3}(?:\\.\\d{1,3}){3}$", var.ipv4_gateway))
    error_message = "ipv4_gateway doit être null ou une IPv4 au format x.x.x.x."
  }
}

variable "datastore_id" {
  description = "Datastore Proxmox pour le disque root."
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Taille du disque root (en Go)."
  type        = number
  default     = 4

  validation {
    condition     = var.disk_size >= 1
    error_message = "disk_size doit être >= 1 (Go)."
  }
}

variable "os_type" {
  description = "Type OS attendu par le provider."
  type        = string
  default     = "debian"
}

variable "template_file_id" {
  description = "ID d'un template existant. Si null, le module utilisera un download_file."
  type        = string
  default     = null
}
variable "template_url" {
  description = "URL du template LXC à télécharger. Utilisé si template_file_id est null."
  type        = string
  default     = null
}

variable "template_datastore" {
  description = "Datastore Proxmox où stocker le template téléchargé. Utilisé si template_file_id est null."
  type        = string
  default     = "USB_Storage"
}

variable "mount_points" {
  description = "Mount Points List"
  type = list(object({
    volume = string
    path   = string
    size   = optional(string)
  }))

  default = []
}

variable "startup_order" {
  description = "Ordre de démarrage Proxmox."
  type        = string
  default     = "3"
}

variable "startup_up_delay" {
  description = "Délai (secondes) avant de démarrer après l'ordre."
  type        = string
  default     = "0"
}

variable "startup_down_delay" {
  description = "Délai (secondes) avant d'arrêter."
  type        = string
  default     = "0"
}

variable "root_password_length" {
  description = "Longueur du mot de passe généré pour l'utilisateur (root)."
  type        = number
  default     = 20

  validation {
    condition     = var.root_password_length >= 20
    error_message = "root_password_length doit être >= 20."
  }
}

variable "tags" {
  description = "Liste des tags à appliquer au conteneur."
  type        = list(string)
  default     = []
}

locals {
  unprivileged       = true
  protection_enabled = false
  wait_for_ipv4      = true
}
