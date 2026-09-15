output "client_id" {
  description = "Identifiant client OAuth2. Circule dans l'URL d'autorisation, ce n'est pas un secret."
  value       = random_id.client_id.hex
}

output "client_secret" {
  description = "Secret client. null pour un client public."
  value       = var.client_type == "confidential" ? random_password.client_secret.result : null
  sensitive   = true
}

output "slug" {
  description = "Identifiant court de l'application."
  value       = authentik_application.this.slug
}

output "groups" {
  description = "Groupes créés pour cette application."
  value       = { for k, g in authentik_group.this : k => g.id }
}