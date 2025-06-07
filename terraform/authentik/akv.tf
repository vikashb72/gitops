data "azurerm_key_vault" "akv" {
  name                = var.akv_name
  resource_group_name = var.akv_rg
}

#data "azurerm_key_vault_secret" "authentik_clients_akv" {
#  for_each = { for p in var.oauth2_providers : p.name => p }
#
#  key_vault_id = data.azurerm_key_vault.akv.id
#  name = each.value.secret_name
#}

