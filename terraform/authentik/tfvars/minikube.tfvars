environment        = "minikube"
authentik_url      = "https://authentik.minikube.where-ever.net"
service_connection = "120cbb17-f3a4-42ac-bcf2-80c93caeb4ba"

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
  },
  {
    key            = "kafka-ui"
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
    key            = "oauth2-proxy"
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
    external_host = "https://vault-ui.minikube.where-ever.net/",
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

#admin_group = "736d56b6-f86c-4b90-8e29-b1f9feed563f"
#oauth2_groups = {
#  "ArgoCD Admins" = "a95aafb1-1b09-4596-92c1-29df26ecdc7b"
#  "ArgoCD Viewers" = "09d51c4f-167f-4bb2-90e3-2e3bcc46b6e5"
#  "Grafana Admins" = "d02c440d-ec34-443a-abff-c91bbdd3314c"
#  "Grafana Editors" = "bdf96bca-5ab4-4095-8571-5a2bdf3504ac"
#  "Grafana Viewers" = "bfc51dc1-e586-4051-ae3f-7fcbe0bfb022"
#  "Kafka UI Admins" = "0ae2bb66-dc2a-487d-9c66-1413f82ac4cb"
#  "Kafka UI Viewers" = "0e24ce25-2c31-4fd5-9039-ed08d5ec33a1"
#  "oauth2 proxy" = "2dac679a-3a9c-49ec-be27-58ecfd69546f"
#}
#proxy_groups = {
#  "alertmanager Access" = "4fcec68f-238f-44dd-be74-19fd00f8792f"
#  "goldilocks Access" = "280eb34e-3a8f-4659-bb1b-1a6efa5f0522"
#  "homepage Access" = "5f121c79-8714-4a5b-94b3-ced0189b96e0"
#  "prometheus Access" = "9e62d9a3-8351-400a-b8f6-620b3493ac2c"
#  "vault Access" = "f621dc5c-20ed-49a9-8efc-890116b99770"
#}

users = [
  {
    username  = "vikash.badal"
    name      = "Vikash Badal"
    email     = "vikash.badal@minikube.where-ever.net"
    groups    =  [
        "736d56b6-f86c-4b90-8e29-b1f9feed563f",
        "a95aafb1-1b09-4596-92c1-29df26ecdc7b",
        "d02c440d-ec34-443a-abff-c91bbdd3314c",
        "0ae2bb66-dc2a-487d-9c66-1413f82ac4cb",
        "4fcec68f-238f-44dd-be74-19fd00f8792f",
        "280eb34e-3a8f-4659-bb1b-1a6efa5f0522",
        "5f121c79-8714-4a5b-94b3-ced0189b96e0",
        "9e62d9a3-8351-400a-b8f6-620b3493ac2c",
        "f621dc5c-20ed-49a9-8efc-890116b99770",
        "2dac679a-3a9c-49ec-be27-58ecfd69546f"
    ]
  }
]
