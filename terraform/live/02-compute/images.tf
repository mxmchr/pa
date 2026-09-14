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
    url       = "https://cloud.debian.org/images/cloud/trixie/20260831-2587/debian-13-genericcloud-amd64-20260831-2587.qcow2"
    file_name = "debian-13-genericcloud-amd64.qcow2"
    checksum  = "8ea9faae810043a0b35b0149f05014f26705c2339ffb11ead308f33e844a87cc3ef46ec81d5262b38817b6a88af404874d48a5857ebe072ef6a31dfb6e371f50"
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