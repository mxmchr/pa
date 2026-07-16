############################################
###           Connexion Proxmox          ###
############################################

# variable "proxmox_api_url" {
#   description = "URL de l'API Proxmox"
#   type        = string
# }

# variable "proxmox_api_token_id" {
#   description = "ID du token API Proxmox"
#   type        = string
# }

# variable "proxmox_api_token_secret" {
#   description = "Secret du token API Proxmox"
#   type        = string
#   sensitive   = true
# }

# variable "proxmox_tls_insecure" {
#   description = "Désactive la vérification TLS (non recommandé en prod)"
#   type        = bool
#   default     = false
# }

# variable "ssh_private_key_path" {
#   description = "Chemin vers la clé privée SSH pour se connecter aux nœuds Proxmox"
#   type        = string
#   default     = "~/.ssh/id_rsa"
# }

# variable "ssh_username" {
#   description = "Nom d'utilisateur SSH pour se connecter aux nœuds Proxmox"
#   type        = string
#   default     = "root"
# }


# variable "ssh_port" {
#   description = "Port SSH pour se connecter aux nœuds Proxmox"
#   type        = number
#   default     = 22
# }

# variable "proxmox_address" {
#   description = "Adresse IP ou hostname du nœud Proxmox pour la connexion SSH"
#   type        = string
# }

# variable "cf_api_token" {
#   description = "Token API Cloudflare"
#   type        = string
#   sensitive   = true
# }

############################################
### Zone SDN VLAN + VNets                 ###
### Plan d'adressage : 10.0.0.0/16, un    ###
### /24 par VLAN (LAN=.10, SRV=.20, ...)  ###
############################################

variable "sdn_zone" {
  description = "Configuration de la zone SDN VLAN + VNets/Subnets (LAN, SRV, DMZ, ADM, BCK, DEV)."
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

  default = {
    sdn_id     = "pa"
    sdn_bridge = "vmbr0" # TODO: confirmer le bridge lié au NIC sdn_trunk
    apply_changes = true

    vnets = {
      lan = { tag = 10, subnet = { cidr = "10.0.10.0/24", gateway = "10.0.10.1" } }
      srv = { tag = 20, subnet = { cidr = "10.0.20.0/24", gateway = "10.0.20.1" } }
      dmz = { tag = 30, subnet = { cidr = "10.0.30.0/24", gateway = "10.0.30.1" } }
      adm = { tag = 40, subnet = { cidr = "10.0.40.0/24", gateway = "10.0.40.1" } }
      bck = { tag = 50, subnet = { cidr = "10.0.50.0/24", gateway = "10.0.50.1" } }
      dev = { tag = 60, subnet = { cidr = "10.0.60.0/24", gateway = "10.0.60.1" } }
    }
  }
}
