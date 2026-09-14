############################################
### Pool et valeurs communes              ###
############################################
# La connexion au cluster vient de PROXMOX_VE_ENDPOINT, PROXMOX_VE_INSECURE et
# PROXMOX_VE_API_TOKEN, et le backend de AWS_ACCESS_KEY_ID et
# AWS_SECRET_ACCESS_KEY. Aucune de ces valeurs n'est déclarée ici.

variable "pool_id" {
  description = "Pool de ressources Proxmox regroupant les workloads."
  type        = string
  default     = "pa"
}

variable "sdn_zone_id" {
  description = <<-EOT
    Identifiant de la zone SDN créée par terraform/live/01-sdn, repris pour
    l'ACL du groupe opérateur. Les deux states étant séparés, la valeur est
    dupliquée volontairement plutôt que lue par terraform_remote_state.
  EOT
  type        = string
  default     = "pa"
}

variable "storage_paths" {
  description = "Stockages sur lesquels le groupe opérateur reçoit des droits."
  type        = list(string)
  default     = ["pa-pool", "local"]
}

variable "shared_datastore_id" {
  description = <<-EOT
    Stockage partagé Ceph RBD, créé en phase 04. Obligatoirement partagé : un
    workload posé sur un stockage local ne peut pas être migré, donc pas placé
    sous gestion HA.
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
### Workloads conteneurisés               ###
############################################

variable "lxcs" {
  description = "Définition des workloads conteneurisés."
  type = map(object({
    description = optional(string, "Managed by Terraform")
    node_name   = optional(string, "pve1")
    vm_id       = number
    lxc_pool_id = optional(string, null)
    tags        = optional(list(string), [])

    cores        = optional(number, 1)
    units        = optional(number, 1024)
    architecture = optional(string, "amd64")
    memory_size  = number
    swap_size    = optional(number, 512)

    hostname    = string
    dns_domain  = optional(string, "pa.lan")
    dns_servers = optional(list(string), null)

    network_interface_name = optional(string, "eth0")
    network_bridge         = string
    mac_address            = optional(string, null)
    mtu                    = optional(number, 1450)
    ipv4_address           = string
    ipv4_gateway           = optional(string, null)

    nesting = optional(bool, true)

    datastore_id     = optional(string, null)
    disk_size        = number
    template_file_id = string

    mount_points = optional(list(object({
      volume = string
      path   = string
      size   = optional(string)
    })), [])

    startup_order  = optional(number, 2)
    timeout_create = optional(number, 5400)
    timeout_delete = optional(number, 3600)
  }))
  default = {}
}

############################################
### Workloads sur machine virtuelle       ###
############################################

variable "vms" {
  description = "Définition des workloads sur machine virtuelle."
  type = map(object({
    name       = string
    node_name  = optional(string, "pve1")
    vm_id      = number
    vm_pool_id = optional(string, null)
    tags       = optional(list(string), [])

    # Absent : l'image est importée depuis le téléchargement déclaré dans
    # images.tf. disk_file_id ne sert qu'aux appliances.
    disk_file_id  = optional(string, null)
    cdrom_file_id = optional(string, null)

    cores       = optional(number, 2)
    sockets     = optional(number, 1)
    cpu_type    = optional(string, "host")
    memory_size = optional(number, 2048)

    machine       = optional(string, "q35")
    bios          = optional(string, "seabios")
    os_type       = optional(string, "l26")
    agent_enabled = optional(bool, false)

    network_devices = list(object({
      bridge      = string
      mac_address = optional(string, null)
      vlan_id     = optional(number, null)
      model       = optional(string, "virtio")
    }))

    cloud_init          = optional(bool, true)
    cloud_init_username = optional(string, "ansible")
    dns_domain          = optional(string, "pa.lan")
    dns_servers         = optional(list(string), null)
    ipv4_address        = optional(string, "dhcp")
    ipv4_gateway        = optional(string, null)

    datastore_id = optional(string, null)
    disk_size    = optional(number, 8)

    keyboard_layout     = optional(string, "fr")
    on_boot             = optional(bool, true)
    startup_order       = optional(number, 3)
    timeout_create      = optional(number, 5400)
    timeout_stop_vm     = optional(number, 1800)
    timeout_shutdown_vm = optional(number, 1800)
  }))
  default = {}
}