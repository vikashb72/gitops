resource "authentik_provider_oauth2" "argocd" {
  name = "Argocd"

  client_id = var.argocd_client_id

  client_secret = var.argocd_client_secret

  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id

  invalidation_flow     = "default-provider-invalidation-flow"
  allowed_redirect_uris = var.argocd_redirect_uris

  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope-email.id,
    data.authentik_property_mapping_provider_scope.scope-profile.id,
    data.authentik_property_mapping_provider_scope.scope-openid.id,
  ]
}

resource "authentik_application" "argocd" {
  name              = "ArgoCD"
  slug              = "argocd"
  protocol_provider = authentik_provider_oauth2.argocd.id
}

resource "authentik_group" "argocd_admins" {
  name = "ArgoCD Admins"
}

resource "authentik_group" "argocd_editors" {
  name = "ArgoCD Editors"
}

resource "authentik_group" "argocd_viewers" {
  name = "ArgoCD Viewers"
}
