locals {
  vnets = {
    for key, vnet in var.sdn_zone.vnets : key => {
      tag        = vnet.tag
      alias      = vnet.alias
      vlan_aware = vnet.vlan_aware

      subnet = {
        cidr            = vnet.cidr
        gateway         = cidrhost(vnet.cidr, 1)
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
  source = "../../modules/sdn_zone"

  sdn_id        = var.sdn_zone.sdn_id
  peers         = var.sdn_zone.peers
  mtu           = var.sdn_zone.mtu
  vnets         = local.vnets
  apply_changes = var.sdn_zone.apply_changes
}