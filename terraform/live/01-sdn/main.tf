locals {
  vnets = {
    for key, vnet in var.sdn_zone.vnets : key => {
      tag        = vnet.tag
      alias      = vnet.alias
      vlan_aware = vnet.vlan_aware

      subnet = {
        cidr    = vnet.cidr
        gateway = cidrhost(vnet.cidr, 1)

        # Le provider impose que le résolveur annoncé appartienne au subnet.
        # On annonce donc la passerelle du segment : OPNsense y relaiera les
        # requêtes vers PowerDNS (10.0.20.5 et .6).
        dhcp_dns_server = cidrhost(vnet.cidr, 1)

        dhcp_range = {
          start = cidrhost(vnet.cidr, 50)
          end   = cidrhost(vnet.cidr, 250)
        }
      }
    }
  }
}

module "sdn" {
  source = "../../modules/sdn_vlan"

  sdn_id        = var.sdn_zone.sdn_id
  sdn_bridge    = var.sdn_zone.sdn_bridge
  vnets         = local.vnets
  apply_changes = var.sdn_zone.apply_changes
}