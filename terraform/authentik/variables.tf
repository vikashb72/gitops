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

variable "oauth2_providers" {
    type = list(any)
}

variable "proxy_providers" {
    type = list(any)
}
