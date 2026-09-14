############################################
### Images système                        ###
############################################

variable "debian_image" {
  description = "Image cloud utilisée par les workloads VM."
  type = object({
    url       = string
    file_name = string
    checksum  = string
    algorithm = optional(string, "sha512")
    datastore = optional(string, "local")
  })

  default = {
    url       = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
    file_name = "debian-13-genericcloud-amd64.qcow2"
    checksum  = "95e110dfcdbd0ed8a82a75ed9579802f9950cabf51a810dcc6388e81bc778188713878b9f28d583a0ea602fbf48b35996ae9ad37f584166d8fbd6489df248f53"
  }
}

locals {
  vm_nodes = distinct([for cfg in var.vms : cfg.node_name])
}

resource "proxmox_virtual_environment_download_file" "debian" {
  for_each = toset(local.vm_nodes)

  content_type       = "import"
  datastore_id       = var.debian_image.datastore
  node_name          = each.value
  url                = var.debian_image.url
  file_name          = var.debian_image.file_name
  checksum           = var.debian_image.checksum
  checksum_algorithm = var.debian_image.algorithm

  upload_timeout = 1800
}