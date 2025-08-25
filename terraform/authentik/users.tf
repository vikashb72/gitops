resource "authentik_user" "users" {
  for_each = { for u in var.users : u.username => u }

  username  = each.value.username
  name      = each.value.name
  email     = each.value.email
  is_active = true
  groups    = each.value.groups

  depends_on = [
    data.authentik_group.admins,
    authentik_group.oauth2_groups,
    authentik_group.proxy_groups
  ]
}

#resource "authentik_user" "user_tokens" {
#  for_each = { for u in var.users : u.username => u }
#
#  identifier  = format("%s-token", each.value.username)
#  user        = authentik_user.users[each.value.username].id
#  description = "My secret token"
#  expires     = "2025-01-01T15:04:05Z"
#}
