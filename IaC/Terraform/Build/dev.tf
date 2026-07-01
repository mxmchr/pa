module "pool-dev" {
  source = "./modules/pool"

  pool_id = var.pool_id
}

module "sdn_dev" {
  source = "./modules/sdn_vlan"

  sdn_id       = var.sdn_dev.sdn_id
  sdn_bridge   = var.sdn_dev.sdn_bridge
  vnets        = var.sdn_dev.vnets
  apply_changes = var.sdn_dev.apply_changes
}

module "capabilities_dev" {
  source = "./modules/capabilities"
  pool = var.pool_id
  depends_on = [ module.pool-dev, module.sdn_dev ]
}

module "lxc_portainer" {
    source = "./modules/lxc"
    for_each = var.lxcs
    
    description = each.value.description
    node_name   = each.value.node_name
    vm_id       = each.value.vm_id
    
    pool_id = each.value.lxc_pool_id

    tags = each.value.tags

    cores = each.value.cores
    units = each.value.units
    architecture = each.value.architecture

    memory_size = each.value.memory_size
    swap_size   = each.value.swap_size

    hostname    = each.value.hostname
    dns_domain  = each.value.dns_domain
    dns_servers = each.value.dns_servers

    network_interface_name = each.value.network_interface_name
    network_bridge         = each.value.network_bridge
    mac_address            = each.value.mac_address
    ipv4_address           = each.value.ipv4_address
    ipv4_gateway           = each.value.ipv4_gateway

    datastore_id = each.value.datastore_id
    disk_size    = each.value.disk_size

    template_file_id = each.value.template_file_id

    mount_points = each.value.mount_points

    startup_order = each.value.startup_order

    depends_on = [
      module.pool-dev, 
      module.sdn_dev
      ]
}

module "vm-dev" {
  source = "./modules/vm"
  depends_on = [
    module.pool-dev,
    module.sdn_dev
  ]
}