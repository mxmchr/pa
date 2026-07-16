resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.node_name
  vm_id     = var.vm_id
  pool_id   = var.pool_id

  tags = var.tags

  clone {
    vm_id = var.clone_vm_id
  }

  agent {
    enabled = true
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
  }

  initialization {
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
      keys = [
        trimspace(tls_private_key.root_key.public_key_openssh)
      ]
      password = random_password.root_password.result
    }
  }

  keyboard_layout = var.keyboard_layout
  machine         = var.machine

  network_device {
    bridge      = var.network_bridge
    mac_address = var.mac_address
    model       = "virtio"
  }

  on_boot = var.on_boot

  operating_system {
    type = "l26"
  }

  scsi_hardware = "virtio-scsi-single"

  startup {
    order      = var.startup_order
    up_delay   = var.startup_up_delay
    down_delay = var.startup_down_delay
  }

  stop_on_destroy  = true
  purge_on_destroy = true

  depends_on = [
    random_password.root_password,
    tls_private_key.root_key
  ]
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

output "vm_id" {
  description = "L'ID de la VM créée."
  value       = proxmox_virtual_environment_vm.this.vm_id
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
