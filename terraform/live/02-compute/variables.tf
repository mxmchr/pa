############################################
### Pool                                  ###
############################################

variable "pool_id" {
  description = "L'ID du pool de ressources Proxmox VE."
  type        = string
  default     = "pa"
}

variable "shared_datastore_id" {
  description = <<-EOT
    Storage partagé Ceph RBD (créé en phase 04 par `pveceph pool create --add_storages`).
    Obligatoirement partagé : un workload sur un storage local ne peut pas être
    migré, donc pas placé sous HA (terraform/live/03-ha).
  EOT
  type        = string
  default     = "pa-pool"
}

variable "dns_servers_default" {
  description = "Résolveurs par défaut des workloads (PowerDNS, segment SRV)."
  type        = list(string)
  default     = ["10.0.20.5", "10.0.20.6"]
}

############################################
### LXC                                   ###
############################################

variable "lxcs" {
  description = "Définition des conteneurs LXC"
  type = map(object({
    description = optional(string, "Managed by Terraform")
    node_name   = optional(string, "pve1")
    vm_id       = number                      # <- plus optionnel, cf. A.4
    lxc_pool_id = optional(string, null)
    tags        = optional(list(string), [])

    cores        = optional(number, 1)
    units        = optional(number, 1024)
    architecture = optional(string, "amd64")

    memory_size = number
    swap_size   = optional(number, 512)

    hostname    = string
    dns_domain  = optional(string, "pa.lan")
    dns_servers = optional(list(string), null)

    network_interface_name = optional(string, "eth0")
    network_bridge         = string
    mac_address            = optional(string, null)
    ipv4_address           = string
    ipv4_gateway           = optional(string, null)

    nesting = optional(bool, false)

    datastore_id     = optional(string, null)
    disk_size        = number
    template_file_id = string

    mount_points = optional(list(object({
      volume = string
      path   = string
      size   = optional(number)
    })), [])

    startup_order = optional(number, 2)
  }))
  default = {}
}

############################################
### VM                                    ###
############################################

variable "vms" {
  description = "Définition des VM QEMU"
  type = map(object({
    name       = string
    node_name  = optional(string, "pve1")
    vm_id      = number
    vm_pool_id = optional(string, null)
    tags       = optional(list(string), [])

    clone_vm_id = number

    cores       = optional(number, 2)
    sockets     = optional(number, 1)
    cpu_type    = optional(string, "x86-64-v2-AES")
    memory_size = optional(number, 2048)

    hostname    = string
    dns_domain  = optional(string, "pa.lan")
    dns_servers = optional(list(string), null)

    network_bridge = string
    mac_address    = optional(string, null)
    ipv4_address   = optional(string, "dhcp")
    ipv4_gateway   = optional(string, null)

    datastore_id = optional(string, null)
    disk_size    = optional(number, 8)

    keyboard_layout = optional(string, "fr")
    machine         = optional(string, "q35")
    on_boot         = optional(bool, true)

    startup_order = optional(number, 3)
  }))
  default = {}
}
