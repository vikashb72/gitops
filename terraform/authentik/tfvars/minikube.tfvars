environment        = "minikube"
authentik_url      = "https://authentik.minikube.where-ever.net"
service_connection = "5dc4989a-c9bb-4464-b459-0d5050ee467a"

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

# data.authentik_group.admins.id 2a25abf6-30a0-4ee0-993b-85e9e6c4c959
# argocd-ArgoCD-Admins           f1b95697-7d3e-4aae-9055-4d9efcfc0fb4
# grafana-Grafana-Admins         c75f543f-69f5-42e9-91e1-585aecb3cbb0
# alertmanager Access            14fb6b41-6d73-40d2-9fe7-501eb4a1d15d
# echoserver Access              28b62318-a9e9-4e61-872d-6c91bb67041f
# goldilocks Access              9767bc3a-fa62-495f-8745-08bda8db3250
# homepage Access                9df554fa-85a0-47f6-90c5-d60c29c0efab
# httpbin Access                 d8363fd1-c544-4127-b97b-410a7a44fbfe
# prometheus Access              49724385-60df-4bac-8a98-69ee44e22f98
# vault Access                   0a0bb670-cec6-4622-aa8c-24ed84830237

users = [
  {
    username  = "vikash.badal"
    name      = "Vikash Badal"
    email     = "vikash.badal@minikube.where-ever.net"
    groups    =  [
      "2a25abf6-30a0-4ee0-993b-85e9e6c4c959",
      "f1b95697-7d3e-4aae-9055-4d9efcfc0fb4",
      "c75f543f-69f5-42e9-91e1-585aecb3cbb0",
      "d8363fd1-c544-4127-b97b-410a7a44fbfe",
      "14fb6b41-6d73-40d2-9fe7-501eb4a1d15d",
      "28b62318-a9e9-4e61-872d-6c91bb67041f",
      "9767bc3a-fa62-495f-8745-08bda8db3250",
      "9df554fa-85a0-47f6-90c5-d60c29c0efab",
      "49724385-60df-4bac-8a98-69ee44e22f98",
      "0a0bb670-cec6-4622-aa8c-24ed84830237"
    ]
  },
  {
    username  = "httpbin.user"
    name      = "httpbin User"
    email     = "httpbin.user@minikube.where-ever.net"
    groups    =  [ "d8363fd1-c544-4127-b97b-410a7a44fbfe" ]
  }
]
