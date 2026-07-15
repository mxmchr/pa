resource "proxmox_virtual_environment_role" "role_storage" {
  role_id = local.role_id_storage
  privileges = [
    "Datastore.Audit",
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.AllocateTemplate"
  ]
}

resource "proxmox_virtual_environment_role" "role_netork" {
  role_id = local.role_id_network
  privileges = [
    "SDN.Audit",
    "SDN.Use",
    "SDN.Allocate"
  ]
}

resource "proxmox_virtual_environment_role" "role_pool" {
  role_id = local.role_id_pool
  privileges = [
    "VM.Allocate",
    "VM.Clone",
    "VM.Config.CDROM",
    "VM.Config.CPU",
    "VM.Config.Disk",
    "VM.Config.HWType",
    "VM.Config.Memory",
    "VM.Config.Network",
    "VM.Config.Options",
    "VM.Migrate",
    "VM.PowerMgmt",
    "VM.Snapshot",
    "VM.Console"
  ]
}


resource "proxmox_virtual_environment_group" "group" {
  group_id = var.pool
  comment  = "Managed by Terraform"

  acl {
    path      = "/pool/${var.pool}"
    role_id  = proxmox_virtual_environment_role.role_pool.role_id
    propagate = true
  }

  acl {
    path      = "/sdn/zones/${var.pool}"
    role_id  = proxmox_virtual_environment_role.role_netork.role_id
    propagate = true
  }

  acl {
    path      = "/storage/local"
    role_id  = proxmox_virtual_environment_role.role_storage.role_id
    propagate = true
  }

  acl {
    path      = "/storage/local-lvm"
    role_id  = proxmox_virtual_environment_role.role_storage.role_id
    propagate = true
  }

  acl {
    path      = "/storage/USB_Storage"
    role_id  = proxmox_virtual_environment_role.role_storage.role_id
    propagate = true
  }
}