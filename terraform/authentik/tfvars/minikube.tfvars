environment = "minikube"
authentik_url = "https://authentik.minikube.where-ever.net"
service_connection = "398b8670-d0d2-4b6d-a5db-72d13cf88adb"
grafana_redirect_uris = [
  {
    matching_mode = "strict",
    url           = "https://grafana.minikube.where-ever.net/login/generic_oauth"
  }
]

grafana_launch_url = "https://grafana.minikube.where-ever.net"

argocd_redirect_uris = [
  {
    matching_mode = "strict",
    url           = "https://argocd.minikube.where-ever.net/dex/callback"
  },
  {
    matching_mode = "strict",
    url           = "https://localhost:8085/auth/callback"
  },
  {
    matching_mode = "regex",
    url           = "https://argocd.minikube.where-ever.net/.*"
  },
]

argocd_launch_url = "https://argocd.minikube.where-ever.net"

httpbin_url = "https://httpbin.minikube.where-ever.net/"
