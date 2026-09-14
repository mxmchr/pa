############################################
### Pare-feu OPNsense                     ###
############################################

variable "opnsense" {
  description = "Définition de la VM du pare-feu inter-zone."
  type = object({
    vm_id     = optional(number, 100)
    name      = optional(string, "fw-pa-01")
    node_name = optional(string, "pve1")

    cores       = optional(number, 2)
    memory_size = optional(number, 4096)
    disk_size   = optional(number, 20)

    wan_bridge = optional(string, "vmbr0")
    segment_bridges = optional(list(string), ["LAN", "SRV", "DMZ", "ADM", "BCK", "DEV", "PUB"])

    iso_file_id = string
  })
}

resource "proxmox_virtual_environment_vm" "opnsense" {
  vm_id     = var.opnsense.vm_id
  name      = var.opnsense.name
  node_name = var.opnsense.node_name
  pool_id   = var.pool_id
  tags      = ["firewall", "infra"]

  description = "Pare-feu inter-zone. Installation manuelle, configuration par API."

  operating_system {
    type = "other"
  }

  bios          = "seabios"
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores   = var.opnsense.cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = var.opnsense.memory_size
  }

  agent {
    enabled = false
  }

  disk {
    datastore_id = var.shared_datastore_id
    interface    = "scsi0"
    size         = var.opnsense.disk_size
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  cdrom {
    file_id = var.opnsense.iso_file_id
  }

  network_device {
    bridge = var.opnsense.wan_bridge
  }

  dynamic "network_device" {
    for_each = var.opnsense.segment_bridges
    content {
      bridge = network_device.value
    }
  }

  serial_device {
    device = "socket"
  }

  on_boot = true

  startup {
    order    = 1
    up_delay = 0
  }

  started = false

  timeout_create      = 5400
  timeout_stop_vm     = 1800
  timeout_shutdown_vm = 1800

  lifecycle {
    ignore_changes = [
      started,
      cdrom,
    ]
  }

  depends_on = [module.pool]
}

output "opnsense_vm_id" {
  description = "VMID du pare-feu, consommé par terraform/live/03-ha."
  value       = proxmox_virtual_environment_vm.opnsense.vm_id
}