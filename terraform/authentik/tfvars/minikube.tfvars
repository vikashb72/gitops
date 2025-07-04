environment        = "minikube"
authentik_url      = "https://authentik.minikube.where-ever.net"
service_connection = "4b095741-015e-4c15-af64-29de06476ab6"

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

#admin_group = "e882e9f6-d601-44f8-a924-14642ae2b67e"
#oauth2_groups = {
#  "ArgoCD Admins" = "5d81a8f7-4ada-4610-9ff4-21739a4d2547"
#  "ArgoCD Viewers" = "41c883e1-4072-4e75-b84a-eb34a5a0b6c8"
#  "Grafana Admins" = "30bd8d1d-7576-483a-8ac4-d525348c6c62"
#  "Grafana Editors" = "da159ef9-6987-4c8c-8709-4ee5e88fe76b"
#  "Grafana Viewers" = "4984a2d3-367f-414c-b768-c6c8145f4833"
#  "Kafka UI Admins" = "adca96c3-ca82-497f-a855-87ba2715c7a2"
#  "Kafka UI Viewers" = "354435f6-3ba2-48ee-b657-a4f6c3beca29"
#}
#proxy_groups = {
#  "alertmanager Access" = "fe66de68-dde7-4e67-922e-d75be2f407b5"
#  "echoserver Access" = "c5150350-9fee-45bd-a178-9cc90010d424"
#  "goldilocks Access" = "52966147-06e4-468a-93df-2e97ccdb6839"
#  "homepage Access" = "e7ec37a2-b754-44cd-8ac3-ce163b431394"
#  "httpbin Access" = "d5dc5a55-6dbd-490a-af54-fb59d616d6b6"
#  "prometheus Access" = "08e80714-471e-43be-a032-08a8366acaa8"
#  "vault Access" = "464b947a-1a0e-4a1f-8910-9e9c6481bd38"
#}

users = [
  {
    username  = "vikash.badal"
    name      = "Vikash Badal"
    email     = "vikash.badal@minikube.where-ever.net"
    groups    =  [
        "e882e9f6-d601-44f8-a924-14642ae2b67e",
        "5d81a8f7-4ada-4610-9ff4-21739a4d2547",
        "30bd8d1d-7576-483a-8ac4-d525348c6c62",
        "adca96c3-ca82-497f-a855-87ba2715c7a2",
        "fe66de68-dde7-4e67-922e-d75be2f407b5",
        "c5150350-9fee-45bd-a178-9cc90010d424",
        "52966147-06e4-468a-93df-2e97ccdb6839",
        "e7ec37a2-b754-44cd-8ac3-ce163b431394",
        "d5dc5a55-6dbd-490a-af54-fb59d616d6b6",
        "08e80714-471e-43be-a032-08a8366acaa8",
        "464b947a-1a0e-4a1f-8910-9e9c6481bd38"
    ]
  }
]
