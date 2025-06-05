resource "authentik_provider_oauth2" "grafana" {
  name      = "Grafana Outh2 Provider"
  client_id = var.grafana_client_id

  client_secret = var.grafana_client_secret

  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id

  #invalidation_flow     = "default-provider-invalidation-flow"
  invalidation_flow     = data.authentik_flow.default-provider-invalidation-flow.id
  allowed_redirect_uris = var.grafana_redirect_uris

  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope-email.id,
    data.authentik_property_mapping_provider_scope.scope-profile.id,
    data.authentik_property_mapping_provider_scope.scope-openid.id,
  ]
}

resource "authentik_application" "grafana" {
  name              = "Grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_oauth2.grafana.id
}

resource "authentik_group" "grafana_admins" {
  name = "Grafana Admins"
}

resource "authentik_group" "grafana_editors" {
  name = "Grafana Editors"
}

resource "authentik_group" "grafana_viewers" {
  name = "Grafana Viewers"
}
