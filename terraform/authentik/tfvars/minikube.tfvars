environment        = "minikube"
authentik_url      = "https://authentik.minikube.where-ever.net"
service_connection = "2210ed4b-d589-48f8-9f45-24439b5f5e82"

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
    key            = "grafana"
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
  }
]

proxy_providers  = [
  {
    key           = "httpbin",
    name          = "httpbin",
    mode          = "forward_single",
    external_host = "https://httpbin.minikube.where-ever.net/",
    groups        = ["httpbin Access"]
  },
  {
    key           = "echoserver",
    name          = "echoserver",
    mode          = "forward_single",
    external_host = "https://echoserver.minikube.where-ever.net/",
    groups        = ["echoserver Access"]
  },
  {
    key           = "prometheus",
    name          = "prometheus",
    mode          = "forward_single",
    external_host = "https://prometheus.minikube.where-ever.net/",
    groups        = ["prometheus Access"]
  },
  {
    key           = "alertmanager",
    name          = "alertmanager",
    mode          = "forward_single",
    external_host = "https://alertmanager.minikube.where-ever.net/",
    groups        = ["alertmanager Access"]
  },
  {
    key           = "vault",
    name          = "vault",
    mode          = "forward_single",
    external_host = "https://vault.minikube.where-ever.net/",
    groups        = ["vault Access"]
  },
  {
    key           = "goldilocks",
    name          = "goldilocks",
    mode          = "forward_single",
    external_host = "https://goldilocks.minikube.where-ever.net/",
    groups        = ["goldilocks Access"]
  },
  {
    key           = "homepage",
    name          = "homepage",
    mode          = "forward_single",
    external_host = "https://homepage.minikube.where-ever.net/",
    groups        = ["homepage Access"]
  }
]

# admin_group = "7184b4f4-c031-4f94-8123-15a6524a809d"
# "ArgoCD Admins" = "d340c1a6-454c-4b8d-9121-f69d8da0a654"
# "ArgoCD Viewers" = "96fffed7-c5ef-4617-a927-a53d40cbb9ce"
# "Grafana Admins" = "800dfba6-6d61-4a03-b9ad-7400f4aa6916"
# "Grafana Editors" = "1f9da5b7-2f5c-46a1-8646-1d05d747c4b7"
# "Grafana Viewers" = "2e0a680b-4963-428e-9c88-301b529a2004"
# "alertmanager Access" = "c95bba94-1c3c-4a13-bd68-d50b198aaae5"
# "echoserver Access" = "05a208c7-d4b2-4740-8bd0-c75c48667448"
# "goldilocks Access" = "cfc24377-75d8-4ee8-a7b2-c5c4d5aaf8b1"
# "homepage Access" = "90716734-0f9b-43cc-940b-9206cb0f453d"
# "httpbin Access" = "b9dd6360-584f-4602-bfbc-79faa2c0f755"
# "prometheus Access" = "fa70baa4-d1f0-40d9-9572-2812268e42b5"
# "vault Access" = "013682bc-168f-4163-9fb9-bff1c6513317"

users = [
  {
    username  = "vikash.badal"
    name      = "Vikash Badal"
    email     = "vikash.badal@minikube.where-ever.net"
    groups    =  [
      "7184b4f4-c031-4f94-8123-15a6524a809d",
      "d340c1a6-454c-4b8d-9121-f69d8da0a654",
      "800dfba6-6d61-4a03-b9ad-7400f4aa6916",
      "c95bba94-1c3c-4a13-bd68-d50b198aaae5",
      "05a208c7-d4b2-4740-8bd0-c75c48667448",
      "cfc24377-75d8-4ee8-a7b2-c5c4d5aaf8b1",
      "90716734-0f9b-43cc-940b-9206cb0f453d",
      "b9dd6360-584f-4602-bfbc-79faa2c0f755",
      "fa70baa4-d1f0-40d9-9572-2812268e42b5",
      "013682bc-168f-4163-9fb9-bff1c6513317"
    ]
  }
]
