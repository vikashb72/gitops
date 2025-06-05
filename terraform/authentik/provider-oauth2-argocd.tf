resource "authentik_provider_oauth2" "argocd" {
  name = "Argocd Outh2 Provider"

  client_id = var.argocd_client_id

  client_secret = var.argocd_client_secret

  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id

  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id

  allowed_redirect_uris = var.argocd_redirect_uris

  signing_key = data.authentik_certificate_key_pair.wherever.id

  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope-email.id,
    data.authentik_property_mapping_provider_scope.scope-profile.id,
    data.authentik_property_mapping_provider_scope.scope-openid.id,
  ]
}

resource "authentik_application" "argocd" {
  name              = "ArgoCD"
  slug              = "argocd"
  meta_launch_url   = var.argocd_launch_url
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

# The policy binding ensures that members of the ArgoCD Admins group have access to the application
resource "authentik_policy_binding" "argocd_access" {
  target = authentik_application.argocd.uuid
  group  = authentik_group.argocd_admins.id
  order  = 0
}
