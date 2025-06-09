output "oauth2_groups" {
  #value = authentik_group.oauth2_groups
  value = {for out in authentik_group.oauth2_groups: out.id => out.name}

}

output "proxy_groups" {
  #value = authentik_group.proxy_groups
  value = {for out in authentik_group.proxy_groups: out.id => out.name}
}
