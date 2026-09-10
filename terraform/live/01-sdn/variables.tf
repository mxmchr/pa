############################################
### Zone SDN VLAN + VNets                 ###
### Plan d'adressage : 10.0.0.0/16, un    ###
### /24 par VLAN (LAN=.10, SRV=.20, ...)  ###
############################################

variable "sdn_zone" {
  description = <<-EOT
    Zone SDN VLAN et ses segments, sous forme courte : un tag et un CIDR par
    VNet. Passerelle, plage DHCP et résolveur sont dérivés du CIDR dans
    main.tf, selon le découpage unique documenté dans plan-adressage.md.
  EOT
  type = object({
    sdn_id     = string
    sdn_bridge = string

    vnets = map(object({
      tag        = number
      cidr       = string
      alias      = optional(string)
      vlan_aware = optional(bool, false)
    }))

    apply_changes = bool
  })

  default = {
    sdn_id        = "pa"
    sdn_bridge    = "vmbr1"
    apply_changes = true

    vnets = {
      lan = { tag = 10, cidr = "10.0.10.0/24" }
      srv = { tag = 20, cidr = "10.0.20.0/24" }
      dmz = { tag = 30, cidr = "10.0.30.0/24" }
      adm = { tag = 40, cidr = "10.0.40.0/24" }
      bck = { tag = 50, cidr = "10.0.50.0/24" }
      dev = { tag = 60, cidr = "10.0.60.0/24" }
      pub = { tag = 70, cidr = "10.0.70.0/24" }
    }
  }
}

variable "dns_servers" {
  description = <<-EOT
    Instances PowerDNS vers lesquelles OPNsense relaie les requêtes des
    workloads. Non consommée par le SDN : le provider impose que le
    résolveur annoncé par DHCP appartienne au subnet, c'est donc la
    passerelle du segment qui est annoncée. Conservée ici comme référence
    pour la configuration d'OPNsense en phase 09.
  EOT
  type        = list(string)
  default     = ["10.0.20.5", "10.0.20.6"]
}
