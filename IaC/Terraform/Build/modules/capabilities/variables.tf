variable "pool" {
  description = "The Proxmox VE resource pool ID to manage."
  type        = string
}

locals {
  role_id_storage = "${var.pool}-storage"
  role_id_network = "${var.pool}-network"
  role_id_pool    = "${var.pool}-pool"
}