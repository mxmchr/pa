resource "proxmox_sdn_zone_vlan" "this" {
  id     = local.sdn_id_upper
  bridge = var.sdn_bridge
  mtu    = var.mtu
  ipam   = var.ipam
  depends_on = [proxmox_sdn_applier.finalizer]
}

resource "proxmox_sdn_vnet" "this" {
  for_each = var.vnets

  id   = local.vnet_id_upper[each.key]
  zone = proxmox_sdn_zone_vlan.this.id

  alias         = coalesce(each.value.alias, local.vnet_alias[each.key])
  tag           = each.value.tag
  isolate_ports = each.value.isolate_ports
  vlan_aware    = each.value.vlan_aware
}

resource "proxmox_sdn_subnet" "this" {
  for_each = var.vnets

  cidr    = each.value.subnet.cidr
  vnet    = proxmox_sdn_vnet.this[each.key].id
  gateway = each.value.subnet.gateway

  dhcp_dns_server = each.value.subnet.dhcp_dns_server
  dns_zone_prefix = each.value.subnet.dns_zone_prefix
  snat            = each.value.subnet.snat
}

resource "proxmox_sdn_applier" "subnet_applier" {
  count = var.apply_changes ? 1 : 0

  lifecycle {
    replace_triggered_by = [
      proxmox_sdn_zone_vlan.this,
      proxmox_sdn_vnet.this,
      proxmox_sdn_subnet.this,
    ]
  }

  depends_on = [
    proxmox_sdn_zone_vlan.this,
    proxmox_sdn_vnet.this,
    proxmox_sdn_subnet.this,
  ]
}

resource "proxmox_sdn_applier" "finalizer" {
}