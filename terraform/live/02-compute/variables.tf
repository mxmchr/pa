############################################
### Connexion Proxmox / Cloudflare       ###
############################################

variable "proxmox_api_url" {
  description = "URL de l'API Proxmox"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "ID du token API Proxmox"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Secret du token API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Désactive la vérification TLS (non recommandé en prod)"
  type        = bool
  default     = false
}

variable "ssh_private_key_path" {
  description = "Chemin vers la clé privée SSH pour se connecter aux nœuds Proxmox"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_username" {
  description = "Nom d'utilisateur SSH pour se connecter aux nœuds Proxmox"
  type        = string
  default     = "root"
}

variable "node_name" {
  description = "Nom du nœud Proxmox sur lequel opérer"
  type        = string
}

variable "ssh_port" {
  description = "Port SSH pour se connecter aux nœuds Proxmox"
  type        = number
  default     = 22
}

variable "proxmox_address" {
  description = "Adresse IP ou hostname du nœud Proxmox pour la connexion SSH"
  type        = string
}

variable "cf_api_token" {
  description = "Token API Cloudflare"
  type        = string
  sensitive   = true
}

############################################
### Pool                                  ###
############################################

variable "pool_id" {
  description = "L'ID du pool de ressources Proxmox VE."
  type        = string
}

############################################
### LXC                                   ###
############################################

variable "lxcs" {
  description = "Définition des conteneurs LXC"
  type = map(object({
    description = optional(string, "Managed by Terraform")
    node_name   = optional(string, "pve1")
    vm_id       = optional(number, null)
    lxc_pool_id = optional(string, null)
    tags        = optional(list(string), [])

    cores        = optional(number, null)
    units        = optional(number, null)
    architecture = optional(string, "amd64")

    memory_size = number
    swap_size   = number

    hostname    = string
    dns_domain  = optional(string, "pa.lan")
    dns_servers = optional(list(string), ["10.0.10.5"])

    network_interface_name = string
    network_bridge         = string
    mac_address             = optional(string, null)
    ipv4_address            = string
    ipv4_gateway             = optional(string, null)

    datastore_id     = optional(string, "local-zfs")
    disk_size        = number
    template_file_id = string

    mount_points = optional(list(object({
      volume = string
      path   = string
      size   = optional(number)
    })), [])

    startup_order = optional(number, "2")
  }))
}

############################################
### VM                                    ###
############################################

variable "vms" {
  description = "Définition des VM QEMU"
  type = map(object({
    name        = string
    node_name   = optional(string, "pve1")
    vm_id       = optional(number, null)
    vm_pool_id  = optional(string, null)
    tags        = optional(list(string), [])

    clone_vm_id = number

    cores    = optional(number, 1)
    sockets  = optional(number, 1)
    cpu_type = optional(string, "x86-64-v2-AES")

    memory_size = optional(number, 2048)

    hostname    = string
    dns_domain  = optional(string, "pa.lan")
    dns_servers = optional(list(string), ["10.0.10.5"])

    network_bridge = string
    mac_address    = optional(string, null)
    ipv4_address   = optional(string, "dhcp")
    ipv4_gateway   = optional(string, null)

    datastore_id = optional(string, "local-lvm")
    disk_size    = optional(number, 8)

    keyboard_layout = optional(string, "fr")
    machine         = optional(string, "q35")
    on_boot         = optional(bool, true)

    startup_order = optional(number, 3)
  }))
  default = {}
}
