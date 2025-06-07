environment        = "minikube"
authentik_url      = "https://authentik.minikube.where-ever.net"
service_connection = "398b8670-d0d2-4b6d-a5db-72d13cf88adb"

oauth2_providers = [
  {
    key            = "argocd",
    name           = "ArgoCD",
    client_id      = "REPLACE_ME",
    client_secret  = "REPLACE_ME",
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
    client_id      = "REPLACE_ME",
    client_secret  = "REPLACE_ME",
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
  }
]

# data.authentik_group.admins.id f146c8e3-dc15-4b6d-a573-56ea7756ed8a
# argocd-ArgoCD-Admins           c74c0d75-4da2-440f-ba59-82a39e6a7ddd
# grafana-Grafana-Admins         83d1dbf8-45ea-49c2-afcf-d45de225d24c
# httpbin-httpbin-Access         166987f6-4bc9-424b-8401-f5898d809198

users = [
  {
    username  = "vikash.badal"
    name      = "Vikash Badal"
    email     = "vikash.badal@minikube.where-ever.net"
    groups    =  [
      "f146c8e3-dc15-4b6d-a573-56ea7756ed8a",
      "c74c0d75-4da2-440f-ba59-82a39e6a7ddd",
      "83d1dbf8-45ea-49c2-afcf-d45de225d24c",
      "166987f6-4bc9-424b-8401-f5898d809198"
    ]
  },
  {
    username  = "httpbin.user"
    name      = "httpbin User"
    email     = "httpbin.user@minikube.where-ever.net"
    groups    =  [ "166987f6-4bc9-424b-8401-f5898d809198" ]
  }
]
