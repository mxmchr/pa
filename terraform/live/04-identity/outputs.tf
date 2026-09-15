output "netbird_client_id" {
  description = "Identifiant client OAuth2, à reporter dans la configuration de NetBird."
  value       = module.netbird.client_id
  sensitive   = true
}