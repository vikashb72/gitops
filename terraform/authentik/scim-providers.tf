resource "authentik_provider_scim" "scim_provider" {
  name         = "test-idp"
  url          = "http://localhost"
  token        = data.vault_kv_secret_v2.idp_token.data.token
  filter_group = authentik_group.idp_group.id

  #exclude_users_service_account = false ?

  property_mappings       = [data.authentik_property_mapping_provider_scim.user.id]
  property_mappings_group = [data.authentik_property_mapping_provider_scim.group.id]
}
