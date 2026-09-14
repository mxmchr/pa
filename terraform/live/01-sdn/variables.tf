variable "sdn_zone" {
  description = <<-EOT
    Zone SDN et ses segments, sous forme courte : un tag et un CIDR par VNet.
    Passerelle et plage DHCP sont dérivées du CIDR dans main.tf.

    Zone VXLAN et non VLAN : la maquette est virtualisée sous VMware
    Workstation, qui transporte les trames non étiquetées entre machines mais
    jette les trames 802.1Q. Cf. docs/decisions/sdn-vxlan.md
  EOT
  type = object({
    sdn_id = string
    peers  = list(string)
    mtu    = optional(number, 1450)

    vnets = map(object({
      tag        = number
      cidr       = string
      alias      = optional(string)
      vlan_aware = optional(bool, false)
    }))

    apply_changes = bool
  })

  default = {
    sdn_id = "pa"

    peers = ["172.16.251.11", "172.16.251.12", "172.16.251.13"]

    mtu = 1450

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