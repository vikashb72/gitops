resource "zitadel_idp_oidc" "default" {
  name                = "Authentik OIDC IDP"
  client_id           = data.vault_kv_secret_v2.oidc.data.id
  client_secret       = data.vault_kv_secret_v2.oidc.data.id
  scopes              = ["openid", "profile", "email"]
  issuer              = "https://authentik.minikube.where-ever.net/application/o/zitadel/"
  is_linking_allowed  = true
  is_creation_allowed = true
  is_auto_creation    = true
  is_auto_update      = true
  is_id_token_mapping = true
  auto_linking        = "AUTO_LINKING_OPTION_EMAIL" # "AUTO_LINKING_OPTION_USERNAME"
}
