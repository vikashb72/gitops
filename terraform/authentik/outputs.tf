output "admin_group" {
  description = "Authentik Admin Group"
  value       = data.authentik_group.admins.id
}

output "oauth2_groups" {
  description = "OAuth2 Groups"
  value       = { for out in authentik_group.oauth2_groups : out.name => out.id }

}

output "proxy_groups" {
  description = "Istio Proxy Groups"
  value       = { for out in authentik_group.proxy_groups : out.name => out.id }
}

output "saml_groups" {
  description = "SAML Groups"
  value       = { for out in authentik_group.saml_groups : out.name => out.id }
}

output "roles" {
  description = "Roles"
  value       = { for out in authentik_rbac_role.roles: out.name => out.id }
}

#output "scim" {
#  description = "SCIM"
#  value       = authentik_provider_scim.scim_provider.id
#}
