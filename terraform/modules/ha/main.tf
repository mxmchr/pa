locals {
  # "vm:100" ou "ct:101" - le format attendu par l'API HA de Proxmox
  ha_resource_ids = {
    for k, v in var.ha_resources : k => "${v.type}:${v.vm_id}"
  }
}

resource "proxmox_hagroup" "this" {
  for_each = var.ha_groups

  group       = each.key
  nodes       = each.value.nodes
  restricted  = each.value.restricted
  no_failback = each.value.no_failback
  comment     = each.value.comment
}

resource "proxmox_virtual_environment_haresource" "this" {
  for_each = var.ha_resources

  resource_id  = local.ha_resource_ids[each.key]
  group        = each.value.group
  state        = each.value.state
  comment      = each.value.comment
  max_relocate = each.value.max_relocate
  max_restart  = each.value.max_restart

  depends_on = [proxmox_hagroup.this]
}
