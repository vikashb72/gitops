environment        = "minikube"
authentik_url      = "https://authentik.minikube.where-ever.net"
service_connection = "d3f3948c-01ca-41a4-abc9-9d3b34626d2c"

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
  {
    key            = "kafka-ui",
    name           = "Kafka UI",
    secret_name    = "minikube/kafka-ui/authentik-client",
    groups         = ["Kafka UI Admins", "Kafka UI Viewers"],
    launch_url     = "https://kafka-ui.minikube.where-ever.net",
    redirect_uris  = [
      {
        "matching_mode" = "strict",
        "url"           = "http://localhost:8080/login/oauth2/code/goauthentic"
      }
    ]
  },
  {
    key            = "zitadel",
    name           = "Zitadel",
    secret_name    = "minikube/zitadel/authentik-client",
    groups         = ["zitadel"],
    launch_url     = "",
    redirect_uris  = [
      {
        "matching_mode" = "strict",
        "url"           = "https://zitadel.minikube.where-ever.net/ui/login/login/externalidp/callback"
      }
    ]
  },
  {
    key            = "oauth2-proxy",
    name           = "OAuth2 Proxy",
    secret_name    = "minikube/oauth2-proxy/authentik-client",
    groups         = ["oauth2 proxy"],
    launch_url     = "",
    redirect_uris  = [
      {
        "matching_mode" = "strict",
        "url"           = "http://oauth2-proxy.oauth2-proxy.svc.cluster.local/oauth2/callback"
      },
      {
        "matching_mode" = "strict",
        "url"           = "http://localhost/oauth2/callback"
      }
    ]
  }
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
  {
    key           = "saml-test",
    name          = "saml-test",
    groups        = ["SAML Test Access"]
  }
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
  {
    key           = "alertmanager",
    name          = "alertmanager",
    mode          = "forward_single",
    external_host = "https://alertmanager.minikube.where-ever.net/",
    groups        = ["alertmanager Access"],
    basic_auth_enabled = false,
    basic_auth_password_attribute = null,
    basic_auth_username_attribute = null,
  },
  {
    key           = "vault",
    name          = "vault",
    mode          = "forward_single",
    external_host = "https://vault-ui.minikube.where-ever.net/",
    groups        = ["vault Access"],
    basic_auth_enabled = false,
    basic_auth_password_attribute = null,
    basic_auth_username_attribute = null,
  },
  {
    key           = "goldilocks",
    name          = "goldilocks",
    mode          = "forward_single",
    external_host = "https://goldilocks.minikube.where-ever.net/",
    groups        = ["goldilocks Access"],
    basic_auth_enabled = false,
    basic_auth_password_attribute = null,
    basic_auth_username_attribute = null,
  },
  {
    key           = "homepage",
    name          = "homepage",
    mode          = "forward_single",
    external_host = "https://homepage.minikube.where-ever.net/",
    groups        = ["homepage Access"],
    basic_auth_enabled = false,
    basic_auth_password_attribute = null,
    basic_auth_username_attribute = null,
  },
  {
    key                = "n8n",
    name               = "n8n",
    mode               = "forward_single",
    external_host      = "https://n8n.minikube.where-ever.net/",
    groups             = ["n8n Access"],
    basic_auth_enabled = true,
    basic_auth_password_attribute = "N8N_BASIC_AUTH_PASSWORD",
    basic_auth_username_attribute = "N8N_BASIC_AUTH_USER"
  },
  {
    key           = "kestra",
    name          = "kestra",
    mode          = "forward_single",
    external_host = "https://kestra.minikube.where-ever.net/",
    groups        = ["kestra Access"],
    basic_auth_enabled = false,
    basic_auth_password_attribute = null,
    basic_auth_username_attribute = null,
  },
]

#admin_group = "774e9e6c-d619-4596-b82d-2711a374fa62"
#idp_groups = "5ed40add-8e6a-4fd6-918c-a4f971cac063"
#oauth2_groups = {
#  "ArgoCD Admins" = "b49ef163-3cd2-49f4-b28a-e17d5d968f5d"
#  "ArgoCD Viewers" = "ae646535-d6ed-4b9c-b375-c1f2a06db298"
#  "Grafana Admins" = "eba1793f-1373-4d6d-9510-4c5ab48aab5f"
#  "Grafana Editors" = "a06c78e1-eb09-41a8-aabf-7f3ac6ef2961"
#  "Grafana Viewers" = "4f8053e3-ae5c-4650-a816-804f081150c3"
#  "Kafka UI Admins" = "1ddeb4b0-cacd-4cc9-850a-1dc550549e44"
#  "Kafka UI Viewers" = "c15dee23-0a33-4bce-bfd3-83a7b9e2550e"
#  "oauth2 proxy" = "15db5e07-4f20-4d59-bda8-bbfac3d5bcde"
#  "zitadel" = "dc371521-9b78-4bfb-9c45-f678a67ca2ff"
#}
#proxy_groups = {
#  "alertmanager Access" = "df6eb397-62a8-4373-a218-6c16308d7eaf"
#  "goldilocks Access" = "f9d2f76b-7380-45d1-8c74-fef592a44d3b"
#  "homepage Access" = "a666d42d-c45f-4d49-8795-475d0ff5a4a3"
#  "kestra Access" = "eb05b708-e3fa-4823-8958-b9bba80a1d55"
#  "n8n Access" = "eb513bf3-7ca2-454e-9b51-f7fb2ade2b91"
#  "prometheus Access" = "05d7555b-17fa-4e1e-b7e8-49b3bf1f4cbd"
#  "vault Access" = "ed9f5f38-07fc-40a5-b618-4707d635cf00"
#}
#roles = {
#  "Dev" = "bf59e00c-88c4-4a6a-8d37-06bd8b106b3e"
#  "DevOps" = "ec897b1c-c5bb-41d9-b5af-4bcd618bf115"
#}
#saml_groups = {
#  "SAML Test Access" = "93be01e1-08c4-46a9-9817-5e09ef94e335"
#}
users = [
  {
    username  = "vikash.badal"
    name      = "Vikash Badal"
    email     = "vikash.badal@minikube.where-ever.net"
    groups    =  [
      "774e9e6c-d619-4596-b82d-2711a374fa62",
      "5ed40add-8e6a-4fd6-918c-a4f971cac063",
      "b49ef163-3cd2-49f4-b28a-e17d5d968f5d",
      "eba1793f-1373-4d6d-9510-4c5ab48aab5f",
      "1ddeb4b0-cacd-4cc9-850a-1dc550549e44",
      "15db5e07-4f20-4d59-bda8-bbfac3d5bcde",
      "dc371521-9b78-4bfb-9c45-f678a67ca2ff",
      "df6eb397-62a8-4373-a218-6c16308d7eaf",
      "f9d2f76b-7380-45d1-8c74-fef592a44d3b",
      "a666d42d-c45f-4d49-8795-475d0ff5a4a3",
      "eb05b708-e3fa-4823-8958-b9bba80a1d55",
      "eb513bf3-7ca2-454e-9b51-f7fb2ade2b91",
      "05d7555b-17fa-4e1e-b7e8-49b3bf1f4cbd",
      "ed9f5f38-07fc-40a5-b618-4707d635cf00"
    ]
  }
]
