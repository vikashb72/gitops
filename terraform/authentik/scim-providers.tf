resource "authentik_provider_scim" "scim_provider" {
  name         = "test-idp"
  url          = "http://localhost"
  token        = data.vault_kv_secret_v2.idp_token.data.token
  filter_group = authentik_group.idp_group.id

  #exclude_users_service_account = false ?

  property_mappings       = [data.authentik_property_mapping_provider_scim.user.id]
  property_mappings_group = [data.authentik_property_mapping_provider_scim.group.id]
}

resource "authentik_application" "scim_idp" {
  name              = "scim-idp"
  slug              = "scim-idp"
  protocol_provider = authentik_provider_scim.scim_provider.id
}

resource "authentik_group" "idp_group" {
  name = "idp-users"
}

resource "authentik_policy_binding" "scim_idp_access" {
  target = authentik_application.scim_idp.uuid
  group  = authentik_group.idp_group.id
  order  = 1

  depends_on = [
    authentik_application.scim_idp,
    authentik_group.idp_group
  ]
}
