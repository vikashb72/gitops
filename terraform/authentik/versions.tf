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

    null = {
      source = "hashicorp/null"
      version = "3.2.4"
    }

    vault = {
      source = "hashicorp/vault"
      version = "5.0.0"
    }

  }

  backend "azurerm" {}
}
