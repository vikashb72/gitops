resource "authentik_provider_proxy" "httpbin" {
  name = "httpbin Istio Proxy Provider"
  mode = "forward_single"

  external_host      = var.httpbin_url
  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id
}

resource "authentik_application" "httpbin" {
  name              = "httpbin"
  slug              = "httpbin"
  protocol_provider = authentik_provider_proxy.httpbin.id
}

resource "authentik_group" "httpbin_admins" {
  name = "Httpbin Access"
}
