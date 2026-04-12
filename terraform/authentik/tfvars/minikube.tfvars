environment         = "minikube"
authentik_url       = "https://authentik.minikube.where-ever.net"
service_connection  = "69d37d8e-fc7d-40e8-b9e5-df6405ddec9e"
embedded_outpost_id =  "8a5ba082-b8dc-4286-85c9-edb64597e7e9"

roles = [
  "DevOps",
  "Dev"
]

groups = [
  "Okta"
]

oauth2_providers = [
  {
    key            = "argocd",
    name           = "ArgoCD",
    secret_name    = "minikube/argocd/authentik-client",
    groups         = ["ArgoCD Admins", "ArgoCD Viewers" ],
    launch_url     = "https://argocd.minikube.where-ever.net",
    redirect_uris  = [
      {
        "matching_mode" = "strict",
        "url"           = "https://argocd.minikube.where-ever.net/dex/callback"
      },
      {
        "matching_mode" = "strict",
        "url"           = "https://localhost:8085/auth/callback"
      },
      {
        "matching_mode" = "regex",
        "url"           = "https://argocd.minikube.where-ever.net/.*"
      }
    ]
  },
  {
    key            = "grafana",
    name           = "Grafana",
    secret_name    = "minikube/grafana/authentik-client",
    groups         = ["Grafana Admins", "Grafana Editors", "Grafana Viewers"],
    launch_url     = "https://grafana.minikube.where-ever.net",
    redirect_uris  = [
      {
        "matching_mode" = "strict",
        "url"           = "https://grafana.minikube.where-ever.net/login/generic_oauth"
      }
    ]
  },
  #{
  #  key            = "kafka-ui",
  #  name           = "Kafka UI",
  #  secret_name    = "minikube/kafka-ui/authentik-client",
  #  groups         = ["Kafka UI Admins", "Kafka UI Viewers"],
  #  launch_url     = "https://kafka-ui.minikube.where-ever.net",
  #  redirect_uris  = [
  #    {
  #      "matching_mode" = "strict",
  #      "url"           = "http://localhost:8080/login/oauth2/code/goauthentic"
  #    }
  #  ]
  #},
  #{
  #  key            = "zitadel",
  #  name           = "Zitadel",
  #  secret_name    = "minikube/zitadel/authentik-client",
  #  groups         = ["zitadel"],
  #  launch_url     = "",
  #  redirect_uris  = [
  #    {
  #      "matching_mode" = "strict",
  #      "url"           = "https://zitadel.minikube.where-ever.net/ui/login/login/externalidp/callback"
  #    }
  #  ]
  #},
  #{
  #  key            = "oauth2-proxy",
  #  name           = "OAuth2 Proxy",
  #  secret_name    = "minikube/oauth2-proxy/authentik-client",
  #  groups         = ["oauth2 proxy"],
  #  launch_url     = "",
  #  redirect_uris  = [
  #    {
  #      "matching_mode" = "strict",
  #      "url"           = "http://oauth2-proxy.oauth2-proxy.svc.cluster.local/oauth2/callback"
  #    },
  #    {
  #      "matching_mode" = "strict",
  #      "url"           = "http://localhost/oauth2/callback"
  #    }
  #  ]
  #}
  #{
  #  key            = "kestra",
  #  name           = "Kestra",
  #  secret_name    = "minikube/kestra/authentik-client",
  #  groups         = ["Kestra"],
  #  launch_url     = "https://kestra.minikube.where-ever.net",
  #  redirect_uris  = [
  #    {
  #      "matching_mode" = "strict",
  #      "url"           = "http://localhost:8080/oauth/callback/authentik"
  #    }
  #  ]
  #}
]

saml_providers   = [
  #{
  #  key           = "saml-test",
  #  name          = "saml-test",
  #  groups        = ["SAML Test Access"]
  #}
]

proxy_providers  = [
  #{
  #  key           = "httpbin",
  #  name          = "httpbin",
  #  mode          = "forward_single",
  #  external_host = "https://httpbin.minikube.where-ever.net/",
  #  groups        = ["httpbin Access"]
  #},
  #{
  #  key           = "echoserver",
  #  name          = "echoserver",
  #  mode          = "forward_single",
  #  external_host = "https://echoserver.minikube.where-ever.net/",
  #  groups        = ["echoserver Access"]
  #},
  {
    key           = "prometheus",
    name          = "prometheus",
    mode          = "forward_single",
    external_host = "https://prometheus.minikube.where-ever.net/",
    groups        = ["prometheus Access"],
    basic_auth_enabled = false,
    basic_auth_password_attribute = null,
    basic_auth_username_attribute = null,
  },
  #{
  #  key           = "alertmanager",
  #  name          = "alertmanager",
  #  mode          = "forward_single",
  #  external_host = "https://alertmanager.minikube.where-ever.net/",
  #  groups        = ["alertmanager Access"],
  #  basic_auth_enabled = false,
  #  basic_auth_password_attribute = null,
  #  basic_auth_username_attribute = null,
  #},
  #{
  #  key           = "vault",
  #  name          = "vault",
  #  mode          = "forward_single",
  #  external_host = "https://vault-ui.minikube.where-ever.net/",
  #  groups        = ["vault Access"],
  #  basic_auth_enabled = false,
  #  basic_auth_password_attribute = null,
  #  basic_auth_username_attribute = null,
  #},
  #{
  #  key           = "goldilocks",
  #  name          = "goldilocks",
  #  mode          = "forward_single",
  #  external_host = "https://goldilocks.minikube.where-ever.net/",
  #  groups        = ["goldilocks Access"],
  #  basic_auth_enabled = false,
  #  basic_auth_password_attribute = null,
  #  basic_auth_username_attribute = null,
  #},
  #{
  #  key           = "homepage",
  #  name          = "homepage",
  #  mode          = "forward_single",
  #  external_host = "https://homepage.minikube.where-ever.net/",
  #  groups        = ["homepage Access"],
  #  basic_auth_enabled = false,
  #  basic_auth_password_attribute = null,
  #  basic_auth_username_attribute = null,
  #},
  #{
  #  key                = "n8n",
  #  name               = "n8n",
  #  mode               = "forward_single",
  #  external_host      = "https://n8n.minikube.where-ever.net/",
  #  groups             = ["n8n Access"],
  #  basic_auth_enabled = true,
  #  basic_auth_password_attribute = "N8N_BASIC_AUTH_PASSWORD",
  #  basic_auth_username_attribute = "N8N_BASIC_AUTH_USER"
  #},
  #{
  #  key           = "kestra",
  #  name          = "kestra",
  #  mode          = "forward_single",
  #  external_host = "https://kestra.minikube.where-ever.net/",
  #  groups        = ["kestra Access"],
  #  basic_auth_enabled = false,
  #  basic_auth_password_attribute = null,
  #  basic_auth_username_attribute = null,
  #},
]

#admin_group = "cf88babb-c6dc-489c-9282-e8bd0c5254c1"
#idp_groups = ""
#oauth2_groups = {
#  "ArgoCD Admins" = "4d59e347-c415-41eb-89f3-d354f15c73dd"
#  "ArgoCD Viewers" = "df6f7218-f5d7-4f9a-9a02-09efe4efa782"
#  "Grafana Admins" = "e0de3db7-c6bc-459f-8485-18105804afee"
#  "Grafana Editors" = "82859ca2-ea5e-4b8c-8948-92f5d5e37f6b"
#  "Grafana Viewers" = "38e65eaf-4b06-4360-8923-4bb4d137cd03"
#}
#proxy_groups = {
#  "prometheus Access" = "307df824-51ff-4dcc-b0a7-1135aac7d1b0
#}
#roles = {
#  "Dev" = "acdf4862-9de8-4d91-a015-9ad896c67929"
#  "DevOps" = "a534ae46-8582-46fc-8151-4ec18404cf04"
#}
#saml_groups = {
#}
users = [
  {
    username  = "vikash.badal"
    name      = "Vikash Badal"
    email     = "vikash.badal@minikube.where-ever.net"
    groups    =  [
    ]
  }
]
