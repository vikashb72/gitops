resource "authentik_rbac_role" "roles" {
  for_each = toset(var.roles)

  name     = each.value
}
