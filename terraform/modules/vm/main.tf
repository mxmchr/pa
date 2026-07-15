resource "proxmox_virtual_environment_vm" "debian_clone" {
  name      = "docker-dev"
  node_name = "pve-lotus-01"
  vm_id     = 2001
  pool_id   = "dev"

  clone {
    vm_id = 9001
  }

  agent {
    enabled = true
  }

  memory {
    dedicated = 2048

  }

  initialization {
    datastore_id = "local-lvm"
    interface    = "ide0"

    dns {
      domain = "h.lotuslazer.fr"
      servers = ["10.0.10.5"]
    }

    ip_config {
      ipv4 {
        address = "dhcp"

      }
    }

    user_account {
      keys = [
        trimspace(tls_private_key.root_key.public_key_openssh)
      ]
      password = random_password.root_password.result
    }
  }
  
  keyboard_layout = "fr"
  machine = "q35"

  network_device {
    bridge      = "SRV"
    mac_address = null
    model       = "virtio"
  }

  on_boot = false

  operating_system {
    type = "l26"
  }

  scsi_hardware = "virtio-scsi-single"

  startup {
    order      = 3
    up_delay   = 0
    down_delay = 0
  }

  tablet_device = false
  tags = []

  stop_on_destroy  = true
  purge_on_destroy = true

  depends_on = [
    random_password.root_password,
    tls_private_key.root_key
  ]

}

resource "random_password" "root_password" {
  length           = 20
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