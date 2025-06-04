resource "authentik_provider_proxy" "httpbin" {
  name = "httpbin"
  mode = "forward_single"

  external_host      = "https://httpbin.prd.iss.nttltd.global.ntt/"
  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = "default-provider-invalidation-flow"
}

resource "authentik_application" "httpbin" {
  name              = "Httpbin"
  slug              = "httpbin"
  protocol_provider = authentik_provider_proxy.httpbin.id
}

resource "authentik_group" "httpbin_admins" {
  name = "Httpbin Admins"
}

resource "authentik_group" "httpbin_editors" {
  name = "Httpbin Editors"
}

resource "authentik_group" "httpbin_viewers" {
  name = "Httpbin Viewers"
}
