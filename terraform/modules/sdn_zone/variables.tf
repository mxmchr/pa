variable "sdn_id" {
  description = "Identifiant de la zone SDN. Forcé en majuscules par Proxmox."
  type        = string
}

variable "peers" {
  description = <<-EOT
    Adresses des nœuds servant de points d'extrémité aux tunnels VXLAN. Le
    transport passe par de l'UDP entre ces adresses : le réseau sous-jacent
    n'a qu'à router de l'IP, sans transporter d'étiquettes 802.1Q.
  EOT
  type        = list(string)
}

variable "mtu" {
  description = <<-EOT
    MTU de la zone. 1450 et non 1500 : l'encapsulation VXLAN coûte 50 octets.
    À remonter si le réseau sous-jacent passe en jumbo frames.
  EOT
  type        = number
  default     = 1450
}

variable "ipam" {
  description = "Gestionnaire d'adresses."
  type        = string
  default     = "pve"
}

variable "vnets" {
  description = "Segments de la zone. tag devient un VNI en VXLAN."
  type = map(object({
    alias         = optional(string)
    tag           = number
    isolate_ports = optional(bool, false)
    vlan_aware    = optional(bool, false)

    subnet = object({
      cidr            = string
      gateway         = string
      dhcp_dns_server = optional(string, null)
      dns_zone_prefix = optional(string, null)
      snat            = optional(bool, null)
      dhcp_range = object({
        start = string
        end   = string
      })
    })
  }))

  validation {
    condition     = length(keys(var.vnets)) == length(toset([for k in keys(var.vnets) : upper(k)]))
    error_message = "Les clefs de vnets doivent être uniques sans tenir compte de la casse."
  }
}

variable "apply_changes" {
  description = "Pousse la configuration vers les nœuds."
  type        = bool
  default     = true
}