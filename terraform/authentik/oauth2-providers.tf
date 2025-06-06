resource "authentik_provider_oauth2" "providers" {
  for_each = { for p in var.oauth2_providers : p.name => p }

  name          = format("%s Outh2 Provider", each.key)
  client_id     = each.value.client_id
  client_secret = each.value.client_secret

  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id

  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id

  allowed_redirect_uris = each.value.redirect_uris

  signing_key = data.authentik_certificate_key_pair.signing_key.id

  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope-email.id,
    data.authentik_property_mapping_provider_scope.scope-profile.id,
    data.authentik_property_mapping_provider_scope.scope-openid.id,
  ]
}

resource "authentik_application" "applications" {
  for_each = { for p in var.oauth2_providers : p.name => p }

  name              = each.value.name
  slug              = each.key
  meta_launch_url   = each.value.launch_url
  protocol_provider = authentik_provider_oauth2.providers[each.key].id
}

resource "authentik_group" "groups" {
  for_each = local.oauth2Groups

  name  = each.value.group
}

# The policy binding ensures that members of the groups have access to the application
resource "authentik_policy_binding" "policy_binding" {
  for_each = local.oauth2Groups

  target = authentik_application.applications[each.value.pname].uuid
  group  = authentik_group.groups[each.key].id
  order  = each.value.idx
}
