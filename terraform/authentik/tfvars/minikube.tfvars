environment = "minikube"
authentik_url = "https://authentik.minikube.where-ever.net"
redirect_uris = [
    {
      matching_mode = "strict",
      url           = "https://grafana.minikube.where-ever.net/login/generic_oauth"
    }
]
