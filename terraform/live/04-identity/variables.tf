variable "authentik_hostname" {
  description = "Nom publié d'Authentik, résolu vers le point d'entrée applicatif."
  type        = string
  default     = "authentik.pa.lan"
}

variable "authentik_token" {
  description = <<-EOT
    Jeton d'API d'Authentik, produit par la variable d'amorçage du rôle
    Ansible authentik et conservé dans .secrets/authentik_api_token.
    Passé par la variable d'environnement TF_VAR_authentik_token.
  EOT
  type        = string
  sensitive   = true
}

variable "authentik_insecure" {
  description = <<-EOT
    Ignore la validation du certificat. Vrai tant que l'autorité interne
    n'est pas installée sur le poste qui exécute Terraform.
  EOT
  type        = bool
  default     = true
}

variable "netbird_hostname" {
  description = "Nom sous lequel le tableau de bord d'accès distant est joint."
  type        = string
  default     = "netbird.pa.lan"
}

variable "netbird_groups" {
  description = "Groupes autorisés à utiliser l'accès distant, cf. tableau 32."
  type        = list(string)
  default     = ["admin-infra", "admin-app", "dev", "utilisateur"]
}