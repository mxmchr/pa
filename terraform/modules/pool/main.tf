resource "proxmox_virtual_environment_pool" "operations_pool" {
  comment = local.comment
  pool_id = var.pool_id
}