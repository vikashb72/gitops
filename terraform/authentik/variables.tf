# required
variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "storage_account" {
  type = string
}

variable "authentik_url" {
  type = string
}

variable "authentik_token" {
  type = string
}

variable "service_connection" {
  type = string
}

variable "environment" {
  type = string
}

variable "grafana_redirect_uris" {
  type = list(any)
}

variable "grafana_launch_url" {
  type = string
}

variable "grafana_client_id" {
  type = string
}

variable "grafana_client_secret" {
  type = string
}

variable "argocd_redirect_uris" {
  type = list(any)
}

variable "argocd_launch_url" {
  type = string
}

variable "argocd_client_id" {
  type = string
}

variable "argocd_client_secret" {
  type = string
}

variable "httpbin_url" {
  type = string
}
