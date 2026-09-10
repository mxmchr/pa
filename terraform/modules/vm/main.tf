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

  # Clone d'un template cloud-init. Absent lorsque le disque provient d'une
  # image importée (appliance).
  dynamic "clone" {
    for_each = var.clone_vm_id == null ? [] : [var.clone_vm_id]
    content {
      vm_id = clone.value
    }
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
    size         = var.disk_size
    interface    = "scsi0"

    # Image importée pour une appliance ; null lors d'un clone, le disque
    # venant alors du template.
    file_id = var.disk_file_id
  }

  # Configuration d'amorçage injectée à une appliance.
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
      interface    = "ide0"

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
        keys     = [trimspace(tls_private_key.root_key[0].public_key_openssh)]
        password = random_password.root_password[0].result
      }
    }
  }

  # L'ordre de la liste fixe l'ordre côté Proxmox : la première interface
  # devient net0. Ne pas réordonner var.network_devices sur une VM existante.
  dynamic "network_device" {
    for_each = var.network_devices
    content {
      bridge      = network_device.value.bridge
      mac_address = network_device.value.mac_address
      vlan_id     = network_device.value.vlan_id
      model       = network_device.value.model
      firewall    = network_device.value.firewall
    }
  }

  on_boot = var.on_boot

  startup {
    order      = var.startup_order
    up_delay   = var.startup_up_delay
    down_delay = var.startup_down_delay
  }

  stop_on_destroy  = true
  purge_on_destroy = true
}

# Identifiants générés uniquement avec cloud-init : une appliance porte sa
# propre configuration et ses propres comptes.
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