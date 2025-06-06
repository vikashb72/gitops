provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id       # ARM_TENANT_ID
  subscription_id = var.subscription_id # ARM_SUBSCRIPTION_ID

  # Storage
  # resource_group_name      = var.tfstate_rg
  # storage_account_name     = "storageaccountdemostf"
  # container_name           = "terraform"
  # key                      = "terraform.tfstate"
  # access_key               = "<storage_account_access_key>" or
  # sas_token                = "<storage_account_sas_token>"
  # Managed Service Identity
  # use_msi = true
}

provider "authentik" {
  url      = var.authentik_url
  token    = var.authentik_token
  insecure = false
}

provider "null" {
  # Configuration options
}
