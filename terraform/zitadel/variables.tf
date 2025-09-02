# required
variable "zorgid" {
   type = string
}

variable "pid" {
   type = string
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "storage_account" {
  type = string
}

variable "vault_address" {
  type = string
}

variable "vault_token" {
  type = string
}

variable "roles" {
  type = list
  default = []
}

variable "grants" {
  type = list
  default = []
}
