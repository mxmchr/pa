variable "pool" {
  description = "The Proxmox VE resource pool ID to manage."
  type        = string
}

variable "storage_paths" {
  description = "Storages sur lesquels le groupe opérateur reçoit les droits."
  type        = list(string)
  default     = ["pa-pool", "local"]
}

locals {
  role_id_storage = "${var.pool}-storage"
  role_id_network = "${var.pool}-network"
  role_id_pool    = "${var.pool}-pool"
}