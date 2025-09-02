data "vault_kv_secret_v2" "oidc" {
  mount    = "kv"
  name     = "infrastructure/zitadel/authentik-client"
}
