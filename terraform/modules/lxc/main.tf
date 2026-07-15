resource "proxmox_virtual_environment_container" "this" {
  description = var.description

  node_name = var.node_name
  vm_id     = var.vm_id

  unprivileged = local.unprivileged

  pool_id = var.pool_id

  protection = local.protection_enabled

  tags = var.tags

  wait_for_ip {
    ipv4 = local.wait_for_ipv4
  }

  features {
    nesting = var.nesting
  }

  cpu {
    architecture = var.architecture
    cores = var.cores
    units = var.units
  }

  memory {
    dedicated = var.memory_size
    swap = var.swap_size
  }
  initialization {
    hostname = var.hostname

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
      keys = [
        trimspace(tls_private_key.root_key.public_key_openssh)
      ]
      password = random_password.root_password.result
    }
  }

  network_interface {
    name        = var.network_interface_name
    bridge      = var.network_bridge
    mac_address = var.mac_address
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }

  operating_system {
  template_file_id = (var.template_file_id != null ? var.template_file_id : proxmox_download_file.this[0].id)
  type             = var.os_type
  }

  dynamic "mount_point" {
    for_each = var.mount_points
    content {
      volume = mount_point.value.volume
      path   = mount_point.value.path
      size   = lookup(mount_point.value, "size", null)
    }
  }

  startup {
    order      = var.startup_order
    up_delay   = var.startup_up_delay
    down_delay = var.startup_down_delay
  }     
  depends_on = [
    proxmox_download_file.this,
    random_password.root_password,
    tls_private_key.root_key
  ]                             
}

resource "proxmox_download_file" "this" {
  count = var.template_file_id == null ? 1 : 0

  content_type = "vztmpl"
  datastore_id = var.template_datastore
  node_name    = var.node_name
  url          = var.template_url
}

resource "random_password" "root_password" {
  length           = var.root_password_length
  override_special = "_%@"
  special          = true
}
resource "tls_private_key" "root_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "root_password" {
  value     = random_password.root_password.result
  sensitive = true
}

output "root_private_key" {
  value     = tls_private_key.root_key.private_key_pem
  sensitive = true
}

output "ssh_public_key" {
  value = tls_private_key.root_key.public_key_openssh
}
