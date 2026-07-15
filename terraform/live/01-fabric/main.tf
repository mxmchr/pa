module "sdn" {
  source = "../../modules/sdn_vlan"

  sdn_id        = var.sdn_zone.sdn_id
  sdn_bridge    = var.sdn_zone.sdn_bridge
  vnets         = var.sdn_zone.vnets
  apply_changes = var.sdn_zone.apply_changes
}

# TODO (phase EVPN) : module "evpn" { source = "../../modules/evpn" ... }
# une fois le contrôleur EVPN / fabric BGP défini.
