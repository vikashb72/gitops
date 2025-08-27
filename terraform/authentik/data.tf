data "authentik_flow" "default-authentication-flow" {
  slug = "default-authentication-flow"
}

data "authentik_flow" "default-provider-authorization-implicit-consent" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-provider-invalidation-flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_property_mapping_provider_scope" "scope-email" {
  name = "authentik default OAuth Mapping: OpenID 'email'"
}

data "authentik_property_mapping_provider_scope" "scope-profile" {
  name = "authentik default OAuth Mapping: OpenID 'profile'"
}

data "authentik_property_mapping_provider_scope" "scope-openid" {
  name = "authentik default OAuth Mapping: OpenID 'openid'"
}

data "authentik_certificate_key_pair" "signing_key" {
  name = "authentik-tls"
}

data "authentik_group" "admins" {
  name = "authentik Admins"
}

# api/v3/propertymappings/provider/saml/
data "authentik_property_mapping_provider_saml" "saml_property_mapping" {
  managed_list = [
    "goauthentik.io/providers/saml/email",
    "goauthentik.io/providers/saml/groups",
    "goauthentik.io/providers/saml/name",
    "goauthentik.io/providers/saml/username"
  ]
}

data "authentik_property_mapping_provider_scim" "user" {
  managed = "goauthentik.io/providers/scim/user"
}

data "authentik_property_mapping_provider_scim" "group" {
  managed = "goauthentik.io/providers/scim/group"
}

data "authentik_flow" "default-source-authentication" {
  slug = "default-source-authentication"
}

data "authentik_flow" "default-source-enrollment" {
  slug = "default-source-enrollment"
}
