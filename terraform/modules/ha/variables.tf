variable "ha_groups" {
  description = <<-EOT
    Groupes HA (le mécanisme de node-affinity réellement supporté aujourd'hui
    par le provider bpg/proxmox - les "HA Rules" PVE 9 ne sont pas encore
    exposées en Terraform, cf. https://github.com/bpg/terraform-provider-proxmox/issues/2097).
    "nodes" est une map nom_du_nœud => priorité (plus haut = préféré, null/0
    si l'ordre n'a pas d'importance). "restricted" empêche tout autre nœud
    d'exécuter les ressources du groupe.
  EOT
  type = map(object({
    nodes       = map(number)
    restricted  = optional(bool, false)
    no_failback = optional(bool, false)
    comment     = optional(string, "Managed by Terraform")
  }))
  default = {}
}

variable "ha_resources" {
  description = <<-EOT
    Ressources placées sous gestion HA. Clé libre (utilisée aussi comme
    identifiant Terraform). "type" + "vm_id" déterminent le format
    "vm:<id>" ou "ct:<id>" attendu par l'API HA. "group" référence une clé
    de var.ha_groups (optionnel : une ressource peut être HA sans groupe
    assigné, auquel cas Proxmox choisit librement le nœud).
  EOT
  type = map(object({
    type         = string # "vm" ou "ct"
    vm_id        = number
    group        = optional(string)
    state        = optional(string, "started") # started | stopped | ignored
    comment      = optional(string, "Managed by Terraform")
    max_relocate = optional(number, 1)
    max_restart  = optional(number, 1)
  }))
  default = {}
}

# NOTE : le "resource-affinity" (co-location ou anti-affinité entre deux
# ressources HA, indépendamment des nœuds) fait partie des nouvelles "HA
# Rules" PVE 9 et n'est pas encore supporté par le provider Terraform à ce
# jour. À ajouter à ce module dès que bpg/proxmox l'expose (issue #2097).
