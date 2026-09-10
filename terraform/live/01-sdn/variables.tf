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
    sdn_bridge = "vmbr1"
    apply_changes = true

        vnets = {
      lan = { tag = 10, subnet = {
        cidr = "10.0.10.0/24", gateway = "10.0.10.1"
        dhcp_dns_server = "10.0.20.5"
        dhcp_ranges = [{ start = "10.0.10.50", end = "10.0.10.250" }]
      }}
      srv = { tag = 20, subnet = {
        cidr = "10.0.20.0/24", gateway = "10.0.20.1"
        dhcp_dns_server = "10.0.20.5"
        dhcp_ranges = [{ start = "10.0.20.50", end = "10.0.20.250" }]
      }}
      dmz = { tag = 30, subnet = {
        cidr = "10.0.30.0/24", gateway = "10.0.30.1"
        dhcp_dns_server = "10.0.20.5"
        dhcp_ranges = [{ start = "10.0.30.50", end = "10.0.30.250" }]
      }}
      adm = { tag = 40, subnet = {
        cidr = "10.0.40.0/24", gateway = "10.0.40.1"
        dhcp_dns_server = "10.0.20.5"
        dhcp_ranges = [{ start = "10.0.40.50", end = "10.0.40.250" }]
      }}
      bck = { tag = 50, subnet = {
        cidr = "10.0.50.0/24", gateway = "10.0.50.1"
        dhcp_dns_server = "10.0.20.5"
        dhcp_ranges = [{ start = "10.0.50.50", end = "10.0.50.250" }]
      }}
      dev = { tag = 60, subnet = {
        cidr = "10.0.60.0/24", gateway = "10.0.60.1"
        dhcp_dns_server = "10.0.20.5"
        dhcp_ranges = [{ start = "10.0.60.50", end = "10.0.60.250" }]
      }}
      pub = { tag = 70, subnet = {
        cidr = "10.0.70.0/24", gateway = "10.0.70.1"
        dhcp_dns_server = "10.0.20.5"
        dhcp_ranges = [{ start = "10.0.70.50", end = "10.0.70.250" }]
      }}
    }
  }
}
