terraform {
  required_version = "~> 1.15"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.110.0"
    }
  }
}

provider "proxmox" {

  # ssh {
  #   username    = var.ssh_username
  #   private_key = file(var.ssh_private_key_path)
  #   agent       = false

  #   node {
  #     name    = var.node_name
  #     address = var.proxmox_address
  #     port    = var.ssh_port
  #   }
  # }
}
