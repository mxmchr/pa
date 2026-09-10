variable "pool" {
  description = "The Proxmox VE resource pool ID to manage."
  type        = string
}

variable "storage_paths" {
  description = "Stockages sur lesquels le groupe opérateur reçoit les droits."
  type        = list(string)
  default     = ["pa-pool", "local"]
}

variable "sdn_zone_id" {
  description = <<-EOT
    Identifiant de la zone SDN sur laquelle porte l'ACL réseau du groupe.
    Le module sdn_vlan force l'identifiant en majuscules : l'ACL doit donc
    viser /sdn/zones/<ID en majuscules>, faute de quoi elle ne s'applique
    à rien.
  EOT
  type        = string
}

locals {
  role_id_storage = "${var.pool}-storage"
  role_id_network = "${var.pool}-network"
  role_id_pool    = "${var.pool}-pool"
}