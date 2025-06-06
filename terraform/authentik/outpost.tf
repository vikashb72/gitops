resource "authentik_outpost" "embedded_outpost" {
  name = "authentik Embedded Outpost"

  protocol_providers = [
    for p in authentik_provider_proxy.proxy_providers : p.id
  ]

  service_connection = var.service_connection

  depends_on = [
    authentik_provider_proxy.proxy_providers
  ]
}
