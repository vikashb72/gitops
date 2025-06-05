resource "authentik_user" "vikashbadal" {
  username  = "vikash.badal"
  name      = "Vikash Badal"
  email     = "vikashb@minikube.where-ever.net"
  is_active = true
  groups    = [
    data.authentik_group.admins.id,
    authentik_group.argocd_admins.id,
    authentik_group.grafana_admins.id,
    authentik_group.httpbin_admins.id
  ]
}

resource "authentik_user" "vikashb" {
  username  = data.authentik_user.vikashb.name
  name      = "Vikash Badal"
  email     = "vikashb@home.where-ever.net"
  is_active = true
  groups    = [
    data.authentik_group.admins.id,
    authentik_group.argocd_admins.id,
    authentik_group.grafana_admins.id,
    authentik_group.httpbin_admins.id
  ]
}
