############################################
### Génération de l'inventaire Ansible    ###
############################################

variable "admin_ssh_public_key" {
  description = <<-EOT
    Clé publique d'administration, injectée dans tous les workloads en plus de
    la clé générée par workload. C'est elle qu'Ansible utilise.
  EOT
  type        = string
}

variable "ansible_private_key_file" {
  description = "Chemin de la clé privée correspondante, côté nœud de contrôle."
  type        = string
  default     = "~/.ssh/proxmox_iac"
}

variable "inventory_path" {
  description = "Emplacement de l'inventaire généré."
  type        = string
  default     = "../../../ansible/inventory/production/hosts_workloads.yml"
}

locals {
  workload_hosts = concat(
    [for key, cfg in var.lxcs : {
      name    = key
      segment = lower(cfg.network_bridge)
      address = split("/", cfg.ipv4_address)[0]
      user    = "root"
      vm_id   = cfg.vm_id
      kind    = "lxc"
    } if cfg.ipv4_address != "dhcp"],
    [for key, cfg in var.vms : {
      name    = key
      segment = lower(cfg.network_devices[0].bridge)
      address = split("/", cfg.ipv4_address)[0]
      user    = cfg.cloud_init_username
      vm_id   = cfg.vm_id
      kind    = "vm"
    } if cfg.ipv4_address != "dhcp"],
  )

  workload_groups = {
    for segment in distinct([for h in local.workload_hosts : h.segment]) :
    segment => [for h in local.workload_hosts : h if h.segment == segment]
  }
}

resource "local_file" "ansible_inventory" {
  filename        = var.inventory_path
  file_permission = "0644"

  content = templatefile("${path.module}/templates/hosts_workloads.yml.tftpl", {
    ssh_private_key_file = var.ansible_private_key_file
    groups               = local.workload_groups
  })
}