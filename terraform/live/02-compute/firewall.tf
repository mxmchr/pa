############################################
### Pare-feu au niveau du workload        ###
############################################
# Second niveau de filtrage du §5.7, au plus près de chaque machine, en
# complément du pare-feu inter-zone. Une erreur de règle sur l'un des deux
# niveaux ne doit pas ouvrir tout le réseau.
#
# Les groupes et leur affectation sont des données, déclarées dans
# firewall.auto.tfvars : ajouter un service revient à ajouter une entrée,
# sans toucher au code.

variable "firewall_enabled" {
  description = <<-EOT
    Active le pare-feu au niveau du cluster. À ne passer à true qu'après
    avoir vérifié les groupes : la politique d'entrée est en rejet, tout
    flux non déclaré est coupé, y compris l'accès du nœud de contrôle.
  EOT
  type        = bool
  default     = false
}

variable "firewall_security_groups" {
  description = "Groupes de sécurité et leurs règles."
  type = map(object({
    comment = optional(string, "")
    rules = list(object({
      action  = optional(string, "ACCEPT")
      type    = optional(string, "in")
      proto   = optional(string, null)
      source  = optional(string, null)
      dest    = optional(string, null)
      dport   = optional(string, null)
      sport   = optional(string, null)
      log     = optional(string, null)
      comment = optional(string, "")
    }))
  }))
  default = {}
}

variable "firewall_workload_groups" {
  description = <<-EOT
    Groupes appliqués à chaque workload. La clef reprend celle de var.lxcs
    ou de var.vms.
  EOT
  type    = map(list(string))
  default = {}
}

resource "proxmox_virtual_environment_cluster_firewall" "this" {
  enabled = var.firewall_enabled

  input_policy = "DROP"

  # Le trafic sortant reste libre : la V1 ne filtre pas les flux initiés par
  # les workloads, ce point est porté par le pare-feu inter-zone.
  output_policy = "ACCEPT"

  log_ratelimit {
    enabled = true
    burst   = 5
    rate    = "1/second"
  }
}

resource "proxmox_virtual_environment_cluster_firewall_security_group" "this" {
  for_each = var.firewall_security_groups

  name    = each.key
  comment = each.value.comment

  dynamic "rule" {
    for_each = each.value.rules
    content {
      action  = rule.value.action
      type    = rule.value.type
      proto   = rule.value.proto
      source  = rule.value.source
      dest    = rule.value.dest
      dport   = rule.value.dport
      sport   = rule.value.sport
      log     = rule.value.log
      comment = rule.value.comment
      enabled = true
    }
  }
}

resource "proxmox_virtual_environment_firewall_rules" "lxc" {
  for_each = {
    for k, v in var.firewall_workload_groups : k => v
    if contains(keys(var.lxcs), k)
  }

  node_name    = var.lxcs[each.key].node_name
  container_id = module.lxc[each.key].vm_id

  dynamic "rule" {
    for_each = each.value
    content {
      security_group = rule.value
      comment        = "Groupe ${rule.value}"
      enabled        = true
    }
  }

  depends_on = [proxmox_virtual_environment_cluster_firewall_security_group.this]
}

resource "proxmox_virtual_environment_firewall_rules" "vm" {
  for_each = {
    for k, v in var.firewall_workload_groups : k => v
    if contains(keys(var.vms), k)
  }

  node_name = var.vms[each.key].node_name
  vm_id     = module.vm[each.key].vm_id

  dynamic "rule" {
    for_each = each.value
    content {
      security_group = rule.value
      comment        = "Groupe ${rule.value}"
      enabled        = true
    }
  }

  depends_on = [proxmox_virtual_environment_cluster_firewall_security_group.this]
}