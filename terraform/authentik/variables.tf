# required
variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "authentik_url" {
  type = string
}

variable "authentik_token" {
  type = string
}

variable "environment" {
  type = string
}

variable "redirect_uris" {
  type = list(any)
}
variable "grafana_client_id" {
  type = string
}

variable "grafana_client_secret" {
  type = string
}
