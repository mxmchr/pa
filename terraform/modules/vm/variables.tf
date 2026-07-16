variable "name" {
  description = "Nom de la VM."
  type        = string
}

variable "node_name" {
  description = "Nom du nœud Proxmox sur lequel créer la VM."
  type        = string
}

variable "vm_id" {
  description = "VMID Proxmox."
  type        = number
}

variable "pool_id" {
  description = "Pool ID"
  type        = string
}

variable "clone_vm_id" {
  description = "VMID du template à cloner (cloud-init déjà préparé). Ce module ne construit pas de template depuis une image cloud - prérequis à créer une fois en amont (proxmox_virtual_environment_download_file + VM one-shot convertie en template)."
  type        = number
}

variable "cores" {
  description = "Nombre de vCPU."
  type        = number
  default     = 1
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

variable "hostname" {
  description = "Hostname (cloud-init)."
  type        = string
}

variable "dns_domain" {
  description = "Search domain (cloud-init)."
  type        = string
}

variable "dns_servers" {
  description = "Liste des serveurs DNS (cloud-init)."
  type        = list(string)
}

variable "network_bridge" {
  description = "Bridge Proxmox (ex: vmbr0, SRV, DMZ...)."
  type        = string
  default     = "vmbr0"
}

variable "mac_address" {
  description = "Adresse MAC de l'interface réseau."
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
  description = "Passerelle IPv4. Laisser null si DHCP."
  type        = string
  default     = null

  validation {
    condition     = var.ipv4_gateway == null || can(regex("^\\d{1,3}(?:\\.\\d{1,3}){3}$", var.ipv4_gateway))
    error_message = "ipv4_gateway doit être null ou une IPv4 au format x.x.x.x."
  }
}

variable "datastore_id" {
  description = "Datastore Proxmox pour le disque cloud-init / la conf de la VM."
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Taille du disque principal (Go). Doit être >= à celle du template source."
  type        = number
  default     = 8
}

variable "keyboard_layout" {
  description = "Layout clavier."
  type        = string
  default     = "fr"
}

variable "machine" {
  description = "Type de machine QEMU."
  type        = string
  default     = "q35"
}

variable "on_boot" {
  description = "Démarrage automatique de la VM avec le nœud."
  type        = bool
  default     = true
}

variable "startup_order" {
  description = "Ordre de démarrage Proxmox."
  type        = number
  default     = 3
}

variable "startup_up_delay" {
  description = "Délai (secondes) avant de démarrer après l'ordre."
  type        = number
  default     = 0
}

variable "startup_down_delay" {
  description = "Délai (secondes) avant d'arrêter."
  type        = number
  default     = 0
}

variable "root_password_length" {
  description = "Longueur du mot de passe généré pour l'utilisateur cloud-init."
  type        = number
  default     = 20

  validation {
    condition     = var.root_password_length >= 20
    error_message = "root_password_length doit être >= 20."
  }
}

variable "tags" {
  description = "Liste des tags à appliquer à la VM."
  type        = list(string)
  default     = []
}
