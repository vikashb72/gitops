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

provider "zitadel" {
  domain           = "zitadel.minikube.where-ever.net"
  insecure         = false
  #jwt_profile_file = "./335941570031256291.json"
  jwt_profile_file = "./336038031674835477.json" # this works IAM login client
  port             = 443
}

provider "null" {
  # Configuration options
}

provider "vault" {
  # Configuration options
  address = var.vault_address
  token   = var.vault_token
}
