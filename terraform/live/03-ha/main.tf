# Lit les vmid des LXC/VM créés par terraform/live/02-compute (state séparé :
# la conf HA doit pouvoir évoluer sans jamais toucher à la définition des
# workloads eux-mêmes).
data "terraform_remote_state" "compute" {
  backend = "s3"
  config = {
    bucket                      = "pa-terraform"
    key                         = "compute/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

locals {
  # Seuls les LXC/VM listés dans var.ha_managed_lxc_keys / var.ha_managed_vm_keys
  # passent sous HA - tout le reste (dev/test, ponctuel...) reste hors gestion HA.
  lxc_ha_resources = {
    for k in var.ha_managed_lxc_keys : "lxc-${k}" => {
      type    = "ct"
      vm_id   = data.terraform_remote_state.compute.outputs.lxc_vm_ids[k]
      group   = lookup(var.ha_resource_groups, k, null)
      state   = "started"
      comment = "Managed by Terraform (compute:lxc:${k})"
    }
  }

  vm_ha_resources = {
    for k in var.ha_managed_vm_keys : "vm-${k}" => {
      type    = "vm"
      vm_id   = data.terraform_remote_state.compute.outputs.vm_vm_ids[k]
      group   = lookup(var.ha_resource_groups, k, null)
      state   = "started"
      comment = "Managed by Terraform (compute:vm:${k})"
    }
  }
}

module "ha" {
  source = "../../modules/ha"

  ha_groups    = var.ha_groups
  ha_resources = merge(local.lxc_ha_resources, local.vm_ha_resources)
}
