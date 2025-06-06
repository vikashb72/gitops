resource "authentik_provider_proxy" "proxy_providers" {
  for_each = { for p in var.proxy_providers : p.name => p }

  name = format("%s Istio Proxy Provider", each.key)
  mode = each.value.mode

  external_host      = each.value.external_host
  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id
}

resource "authentik_application" "proxy_applications" {
  for_each = { for p in var.proxy_providers : p.name => p }

  name              = each.value.name
  slug              = each.value.name
  protocol_provider = authentik_provider_proxy.proxy_providers[each.key].id
}

resource "authentik_group" "proxy_groups" {
  for_each = local.proxyGroups

  name  = each.value.group
}

# The policy binding ensures that members of the group access to the application
resource "authentik_policy_binding" "proxy_access" {
  for_each = local.proxyGroups

  target = authentik_application.proxy_applications[each.value.pname].uuid
  group  = authentik_group.proxy_groups[each.key].id
  order  = each.value.idx
}
