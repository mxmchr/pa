resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.node_name
  vm_id     = var.vm_id
  pool_id   = var.pool_id
  tags      = var.tags

  bios            = var.bios
  machine         = var.machine
  keyboard_layout = var.keyboard_layout
  scsi_hardware   = "virtio-scsi-single"

  agent {
    enabled = var.agent_enabled
  }

  operating_system {
    type = var.os_type
  }

  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = var.cpu_type
  }

  memory {
    dedicated = var.memory_size
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size
    discard      = "on"
    iothread     = true
    ssd          = true

    import_from = var.disk_import_from
    file_id     = var.disk_file_id
  }

  dynamic "cdrom" {
    for_each = var.cdrom_file_id == null ? [] : [var.cdrom_file_id]
    content {
      file_id = cdrom.value
    }
  }

  dynamic "initialization" {
    for_each = var.cloud_init ? [1] : []
    content {
      datastore_id = var.datastore_id

      dns {
        domain  = var.dns_domain
        servers = var.dns_servers
      }

      ip_config {
        ipv4 {
          address = var.ipv4_address
          gateway = var.ipv4_gateway
        }
      }

      user_account {
        username = var.cloud_init_username
        keys = concat(
          [trimspace(tls_private_key.root_key[0].public_key_openssh)],
          var.extra_ssh_keys,
        )
        password = random_password.root_password[0].result
      }
    }
  }

  dynamic "network_device" {
    for_each = var.network_devices
    content {
      bridge      = network_device.value.bridge
      mac_address = network_device.value.mac_address
      vlan_id     = network_device.value.vlan_id
      model       = network_device.value.model
      firewall    = network_device.value.firewall
      mtu         = network_device.value.mtu
    }
  }

  serial_device {
    device = "socket"
  }

  on_boot = var.on_boot

  startup {
    order      = var.startup_order
    up_delay   = var.startup_up_delay
    down_delay = var.startup_down_delay
  }

  stop_on_destroy  = true
  purge_on_destroy = true

  timeout_create      = var.timeout_create
  timeout_stop_vm     = var.timeout_stop_vm
  timeout_shutdown_vm = var.timeout_shutdown_vm
}

resource "random_password" "root_password" {
  count = var.cloud_init ? 1 : 0

  length           = var.root_password_length
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "root_key" {
  count = var.cloud_init ? 1 : 0

  algorithm = "ED25519"
}