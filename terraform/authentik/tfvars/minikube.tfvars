environment        = "minikube"
authentik_url      = "https://authentik.minikube.where-ever.net"
service_connection = "afa89415-d39e-4dc5-bf14-802085fd2903"

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

# data.authentik_group.admins.id b37882bb-b4a6-4f63-9616-e2ce8b503e1b
# argocd-ArgoCD-Admins           fb3f4eae-17a1-4a87-a326-d30d1a07e679
# grafana-Grafana-Admins         88835315-1492-4c76-ad40-b87ed16dde57
# alertmanager Access            2d45d9b6-3e6e-4b37-a7d7-57972274ead8
# echoserver Access              7b5711b1-7a79-4c7a-aeca-0c66c7a74f48
# goldilocks Access              1aa0acc1-9bc3-40f8-8a1e-e9a28d636428
# homepage Access                2d6c09f8-0cfb-4c70-a589-e60b9180e5a4
# httpbin Access                 2375e116-d365-4ccb-9085-0ba96280a4e8
# prometheus Access              5534b1d9-aec4-4ca6-bfc5-60b1ac44dc44
# vault Access                   c663c4ea-04a2-440c-9412-2037239eacc0

users = [
  {
    username  = "vikash.badal"
    name      = "Vikash Badal"
    email     = "vikash.badal@minikube.where-ever.net"
    groups    =  [
      "b37882bb-b4a6-4f63-9616-e2ce8b503e1b",
      "fb3f4eae-17a1-4a87-a326-d30d1a07e679",
      "88835315-1492-4c76-ad40-b87ed16dde57",
      "2375e116-d365-4ccb-9085-0ba96280a4e8",
      "2d45d9b6-3e6e-4b37-a7d7-57972274ead8",
      "7b5711b1-7a79-4c7a-aeca-0c66c7a74f48",
      "1aa0acc1-9bc3-40f8-8a1e-e9a28d636428",
      "2d6c09f8-0cfb-4c70-a589-e60b9180e5a4",
      "5534b1d9-aec4-4ca6-bfc5-60b1ac44dc44",
      "c663c4ea-04a2-440c-9412-2037239eacc0"
    ]
  },
  {
    username  = "httpbin.user"
    name      = "httpbin User"
    email     = "httpbin.user@minikube.where-ever.net"
    groups    =  [ "2375e116-d365-4ccb-9085-0ba96280a4e8" ]
  }
]
