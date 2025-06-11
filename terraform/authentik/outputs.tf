output "admin_group" {
  description = "Authentik Admin Group"
  value = data.authentik_group.admins.id
}

output "oauth2_groups" {
  description = "OAuth2 Groups"
  value = {for out in authentik_group.oauth2_groups: out.name => out.id}

}

output "proxy_groups" {
  description = "Istio Proxy Groups"
  value = {for out in authentik_group.proxy_groups: out.name => out.id}
}
