############################################
### Variables for Proxmox Provider ###
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

############################################
### Variables for Terraform Backend ###
############################################

variable "s3_access_key" {
  description = "Clé d'accès S3"
  type        = string
}

variable "s3_secret_key" {
  description = "Secret S3"
  type        = string
  sensitive   = true
}

variable "s3_endpoint" {
  description = "Endpoint S3"
  type        = string
}

############################################

############################################
### Variables for pool module ###
############################################

variable "pool_id" {
  description = "The ID of the Proxmox VE pool."
  type        = string 
}

############################################

############################################
### Variables pour le module proxmox-lxc ###
############################################

variable "lxcs" {
  description = "LXCs Definition"
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
    dns_domain  = optional(string, "h.lotuslazer.fr")
    dns_servers = optional(list(string), ["10.0.10.5"])

    network_interface_name = string
    network_bridge         = string
    mac_address            = optional(string, null)
    ipv4_address           = string
    ipv4_gateway           = optional(string, null)

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

############################################
### Variables pour le module SDN Proxmox ###
############################################

variable "sdn_dev" {
  description = "Configuration de la zone SDN VLAN de test + VNets + Subnets."
  type = object({
    sdn_id     = string
    sdn_bridge = string

    vnets = map(object({
      alias = optional(string)
      tag   = number

      isolate_ports = optional(bool, false)
      vlan_aware    = optional(bool, false)

      subnet = object({
        cidr    = string
        gateway = string

        dhcp_dns_server = optional(string, null)
        dns_zone_prefix = optional(string, null)
        snat            = optional(bool, null)
      })
    }))

    apply_changes = bool
  })
}
############################################