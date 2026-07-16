# NB d'ordre d'apply : la zone SDN (terraform/live/01-sdn) doit être
# appliquée avant ce root module, car les LXC/VM référencent les bridges
# (network_bridge) créés par la fabric. Terraform ne peut pas exprimer de
# dépendance inter-state automatique ici (state séparé = isolation voulue) ;
# c'est une contrainte d'ordonnancement à respecter côté pipeline/CI.

module "pool" {
  source = "../../modules/pool"

  pool_id = var.pool_id
}

module "capabilities" {
  source = "../../modules/capabilities"

  pool       = var.pool_id
  depends_on = [module.pool]
}

module "lxc" {
  source   = "../../modules/lxc"
  for_each = var.lxcs

  description = each.value.description
  node_name   = each.value.node_name
  vm_id       = each.value.vm_id

  pool_id = each.value.lxc_pool_id

  tags = each.value.tags

  cores        = each.value.cores
  units        = each.value.units
  architecture = each.value.architecture

  memory_size = each.value.memory_size
  swap_size   = each.value.swap_size

  hostname    = each.value.hostname
  dns_domain  = each.value.dns_domain
  dns_servers = each.value.dns_servers

  network_interface_name = each.value.network_interface_name
  network_bridge          = each.value.network_bridge
  mac_address              = each.value.mac_address
  ipv4_address             = each.value.ipv4_address
  ipv4_gateway             = each.value.ipv4_gateway

  datastore_id = each.value.datastore_id
  disk_size    = each.value.disk_size

  template_file_id = each.value.template_file_id

  mount_points = each.value.mount_points

  startup_order = each.value.startup_order

  depends_on = [module.pool]
}

module "vm" {
  source   = "../../modules/vm"
  for_each = var.vms

  name      = each.value.name
  node_name = each.value.node_name
  vm_id     = each.value.vm_id
  pool_id   = each.value.vm_pool_id

  tags = each.value.tags

  clone_vm_id = each.value.clone_vm_id

  cores    = each.value.cores
  sockets  = each.value.sockets
  cpu_type = each.value.cpu_type

  memory_size = each.value.memory_size

  hostname    = each.value.hostname
  dns_domain  = each.value.dns_domain
  dns_servers = each.value.dns_servers

  network_bridge = each.value.network_bridge
  mac_address    = each.value.mac_address
  ipv4_address   = each.value.ipv4_address
  ipv4_gateway   = each.value.ipv4_gateway

  datastore_id = each.value.datastore_id
  disk_size    = each.value.disk_size

  keyboard_layout = each.value.keyboard_layout
  machine         = each.value.machine
  on_boot         = each.value.on_boot

  startup_order = each.value.startup_order

  depends_on = [module.pool]
}
