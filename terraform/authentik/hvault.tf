data "vault_kv_secret_v2" "authentik_clients" {
  for_each = { for p in var.oauth2_providers : p.name => p }

  mount = "kv"
  name  = each.value.secret_name
}

data "vault_kv_secret_v2" "idp_token" {
  mount    = "kv"
  name     = "infrastructure/authentik/idp"
}
