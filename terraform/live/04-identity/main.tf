module "netbird" {
  source = "../../modules/authentik_app"

  name        = "NetBird"
  slug        = "netbird"
  description = "Accès distant Zero Trust"
  category    = "Infrastructure"

  launch_url = "https://${var.netbird_hostname}/"
  redirect_uris = [
    "https://${var.netbird_hostname}/",
    "https://${var.netbird_hostname}/silent-auth",
    "https://${var.netbird_hostname}/peers",
    "http://localhost:53000/",
  ]

  client_type = "public"
  groups      = var.netbird_groups

  scope_mappings = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
    "goauthentik.io/providers/oauth2/scope-offline_access",
  ]
}

output "netbird_client_id" {
  description = "Identifiant client OAuth2, à reporter dans la configuration de NetBird."
  value       = module.netbird.client_id
}

output "netbird_issuer" {
  description = "Émetteur OpenID, à reporter dans la configuration de NetBird."
  value       = "https://${var.authentik_hostname}/application/o/${module.netbird.slug}/"
}