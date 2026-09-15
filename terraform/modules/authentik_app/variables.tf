variable "name" {
  description = "Nom de l'application dans Authentik."
  type        = string
}

variable "slug" {
  description = "Identifiant court, utilisé dans l'URL de l'émetteur OpenID."
  type        = string
}

variable "description" {
  description = "Description affichée sur le portail."
  type        = string
  default     = ""
}

variable "category" {
  description = "Regroupement des applications sur le portail."
  type        = string
  default     = ""
}

variable "launch_url" {
  description = "URL d'accès à l'application depuis le portail."
  type        = string
}

variable "redirect_uris" {
  description = "URI de redirection autorisées après authentification."
  type        = list(string)
}

variable "client_type" {
  description = <<-EOT
    "confidential" pour une application serveur capable de garder un secret,
    "public" pour un client installé sur le poste, qui n'en est pas capable.
  EOT
  type        = string
  default     = "confidential"

  validation {
    condition     = contains(["confidential", "public"], var.client_type)
    error_message = "client_type doit valoir \"confidential\" ou \"public\"."
  }
}

variable "groups" {
  description = <<-EOT
    Groupes autorisés à accéder à l'application. Chaque groupe est créé s'il
    n'existe pas, et lié par une policy. Liste vide : accès à tous.
  EOT
  type        = list(string)
  default     = []
}

variable "scope_mappings" {
  description = "Portées OpenID exposées dans le jeton."
  type        = list(string)
  default = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

variable "authorization_flow_slug" {
  description = "Flux d'autorisation."
  type        = string
  default     = "default-provider-authorization-implicit-consent"
}

variable "invalidation_flow_slug" {
  description = "Flux de déconnexion."
  type        = string
  default     = "default-provider-invalidation-flow"
}

variable "sub_mode" {
  description = "Champ utilisé comme identifiant de sujet dans le jeton."
  type        = string
  default     = "hashed_user_id"
}

variable "access_token_validity" {
  description = "Durée de validité du jeton d'accès."
  type        = string
  default     = "hours=1"
}

variable "refresh_token_validity" {
  description = "Durée de validité du jeton de rafraîchissement."
  type        = string
  default     = "days=30"
}