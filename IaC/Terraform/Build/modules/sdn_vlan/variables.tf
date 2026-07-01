variable "sdn_id" {
  type        = string
  description = "The ID of the SDN zone VLAN."
}

variable "sdn_bridge" {
  type    = string
  description = "The bridge name for the SDN zone VLAN."
}

variable "mtu" {
  type        = number
  default     = null
  description = "The MTU for the SDN zone VLAN."
}

variable "ipam" {
  type        = string
  description = "The IPAM configuration for the SDN zone VLAN."
  default     = "pve"
}

variable "vnets" {
  description = "A map of virtual networks to create within the SDN zone VLAN."

  type = map(object({
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
  validation {
    condition     = length(keys(var.vnets)) == length(toset([for k in keys(var.vnets) : upper(k)]))
    error_message = "vnets keys must be unique case-insensitively."
  }
}

variable "apply_changes" {
  type        = bool
  description = "Applique les changements SDN côté Proxmox."
  default     = true
}

locals {
  sdn_id_upper  = upper(var.sdn_id)
  vnet_id_upper = { for k, _ in var.vnets : k => upper(k) }
  vnet_alias    = { for k, _ in var.vnets : k => "VLAN ${local.vnet_id_upper[k]}" }
}

