terraform {
  required_version = "~> 1.15"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.110.0"
    }
    random = { source = "hashicorp/random", version = "~> 3.7" }
    tls    = { source = "hashicorp/tls",    version = "~> 4.1" }
  }
}

provider "proxmox" {}