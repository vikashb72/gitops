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
