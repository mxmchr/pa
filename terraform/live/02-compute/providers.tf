terraform {
  required_version = "~> 1.15"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.110.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = var.proxmox_tls_insecure

  ssh {
    username    = var.ssh_username
    private_key = file(var.ssh_private_key_path)
    agent       = false

    node {
      name    = var.node_name
      address = var.proxmox_address
      port    = var.ssh_port
    }
  }
}
