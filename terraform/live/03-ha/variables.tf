############################################
### Connexion Proxmox                     ###
############################################

variable "proxmox_api_url" {
  description = "URL de l'API Proxmox"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "ID du token API Proxmox (privilèges cluster-wide HA requis, cf. docs/decisions/)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Secret du token API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  type    = bool
  default = false
}

variable "ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "node_name" {
  type = string
}

variable "ssh_port" {
  type    = number
  default = 22
}

variable "proxmox_address" {
  type = string
}

variable "cf_api_token" {
  type      = string
  sensitive = true
}

############################################
### HA                                    ###
############################################

variable "ha_managed_lxc_keys" {
  description = "Sous-ensemble des clés de var.lxcs (terraform/live/02-compute) à placer sous gestion HA. Tout LXC non listé ici reste hors HA."
  type        = list(string)
  default     = []
}

variable "ha_managed_vm_keys" {
  description = "Sous-ensemble des clés de var.vms (terraform/live/02-compute) à placer sous gestion HA."
  type        = list(string)
  default     = []
}

variable "ha_resource_groups" {
  description = "Assignation optionnelle clé (lxc/vm) => nom de groupe HA (clé de var.ha_groups). Une ressource sans entrée ici est HA sans groupe assigné (Proxmox choisit librement le nœud)."
  type        = map(string)
  default     = {}
}

variable "ha_groups" {
  description = <<-EOT
    Groupes HA - le mécanisme de node-affinity réellement supporté
    aujourd'hui (cf. terraform/modules/ha). "nodes" est une map
    nom_du_nœud => priorité.
  EOT
  type = map(object({
    nodes       = map(number)
    restricted  = optional(bool, false)
    no_failback = optional(bool, false)
    comment     = optional(string, "Managed by Terraform")
  }))
  default = {}
}
