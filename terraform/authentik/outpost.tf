resource "authentik_outpost" "embedded_outpost" {
  name = "authentik Embedded Outpost"
  protocol_providers = [
    authentik_provider_proxy.httpbin.id
  ]

  service_connection = var.service_connection
}

