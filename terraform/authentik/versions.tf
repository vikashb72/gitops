terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.0.0"
    }

    azuread = {
      version = ">= 3.0.0"
    }

    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.4.0"
    }

  }

  backend "azurerm" {}
}
