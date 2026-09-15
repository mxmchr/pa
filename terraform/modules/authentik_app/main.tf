data "authentik_flow" "authorization" {
  slug = var.authorization_flow_slug
}

data "authentik_flow" "invalidation" {
  slug = var.invalidation_flow_slug
}

data "authentik_property_mapping_provider_scope" "scopes" {
  managed_list = var.scope_mappings
}

resource "random_password" "client_id" {
  length  = 40
  special = false
}

resource "random_password" "client_secret" {
  length  = 64
  special = false
}

resource "authentik_provider_oauth2" "this" {
  name      = var.name
  client_id = random_password.client_id.result

  client_type   = var.client_type
  client_secret = var.client_type == "confidential" ? random_password.client_secret.result : null

  authorization_flow = data.authentik_flow.authorization.id
  invalidation_flow  = data.authentik_flow.invalidation.id

  property_mappings = data.authentik_property_mapping_provider_scope.scopes.ids

  allowed_redirect_uris = [
    for uri in var.redirect_uris : {
      matching_mode = "strict"
      url           = uri
    }
  ]

  sub_mode                   = var.sub_mode
  access_token_validity      = var.access_token_validity
  refresh_token_validity     = var.refresh_token_validity
  include_claims_in_id_token = true
}

resource "authentik_application" "this" {
  name              = var.name
  slug              = var.slug
  protocol_provider = authentik_provider_oauth2.this.id
  meta_launch_url   = var.launch_url
  meta_description  = var.description
  group             = var.category
}

resource "authentik_group" "this" {
  for_each = toset(var.groups)

  name = each.value
}

resource "authentik_policy_binding" "access" {
  for_each = toset(var.groups)

  target = authentik_application.this.uuid
  group  = authentik_group.this[each.value].id
  order  = index(var.groups, each.value)
}