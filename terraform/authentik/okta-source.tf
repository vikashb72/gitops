resource "authentik_source_oauth" "name" {
  name                = "okta"
  slug                = "okta"
  authentication_flow = data.authentik_flow.default-source-authentication.id
  enrollment_flow     = data.authentik_flow.default-source-enrollment.id

  provider_type       = "okta"
  consumer_key        = data.vault_kv_secret_v2.okta_oidc.data.id
  consumer_secret     = data.vault_kv_secret_v2.okta_oidc.data.secret
  oidc_well_known_url = data.vault_kv_secret_v2.okta_oidc.data.oidc_url
  access_token_url    = data.vault_kv_secret_v2.okta_oidc.data.access_token_url
  authorization_url   = data.vault_kv_secret_v2.okta_oidc.data.authorization_url
  oidc_jwks_url       = data.vault_kv_secret_v2.okta_oidc.data.oidc_jwks_url
}
