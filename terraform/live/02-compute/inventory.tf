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
  # Seuls les workloads en adressage statique entrent dans l'inventaire : une
  # adresse obtenue par bail n'est pas connue de Terraform.
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

  workload_segments = distinct([for h in local.workload_hosts : h.segment])

    workload_inventory = {
    all = {
      children = {
        workloads = {
          vars = {
            ansible_ssh_private_key_file = var.ansible_private_key_file
            ansible_ssh_common_args      = "-o StrictHostKeyChecking=accept-new"
          }
          children = {
            for segment in local.workload_segments : segment => {
              hosts = {
                for h in local.workload_hosts : h.name => {
                  ansible_host     = h.address
                  ansible_user     = h.user
                  ansible_become   = h.kind == "vm"
                  pa_workload_vmid = h.vm_id
                  pa_workload_kind = h.kind
                } if h.segment == segment
              }
            }
          }
        }
      }
    }
  }
}

resource "local_file" "ansible_inventory" {
  filename        = var.inventory_path
  file_permission = "0644"

  content = <<-EOT
    # Fichier généré par terraform/live/02-compute. Ne pas modifier à la main :
    # toute modification sera écrasée au prochain apply.
    ${yamlencode(local.workload_inventory)}
  EOT
}