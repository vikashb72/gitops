resource "authentik_provider_saml" "saml_provider" {
  for_each = { for p in var.saml_providers : p.name => p }

  name                = format("%s SAML Provider", each.key)
  authorization_flow  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow   = data.authentik_flow.default-provider-invalidation-flow.id
  authentication_flow = data.authentik_flow.default-authentication-flow.id
  issuer              = data.authentik_certificate_key_pair.signing_key.id
  encryption_kp       = data.authentik_certificate_key_pair.signing_key.id
  verification_kp     = data.authentik_certificate_key_pair.signing_key.id
  signing_kp          = data.authentik_certificate_key_pair.signing_key.id
  property_mappings   = data.authentik_property_mapping_provider_saml.saml_property_mapping.ids
  acs_url             = "http://localhost"
}

resource "authentik_application" "saml_applications" {
  for_each = { for p in var.saml_providers : p.name => p }

  name              = each.value.name
  slug              = each.value.name
  protocol_provider = authentik_provider_saml.saml_provider[each.key].id
}

resource "authentik_group" "saml_groups" {
  for_each = local.samlGroups

  name = each.value.group
}


resource "authentik_policy_binding" "saml_access" {
  for_each = local.samlGroups

  target = authentik_application.saml_applications[each.value.pname].uuid
  group  = authentik_group.saml_groups[each.key].id
  order  = each.value.idx

  depends_on = [
    authentik_application.saml_applications,
    authentik_group.saml_groups
  ]
}
