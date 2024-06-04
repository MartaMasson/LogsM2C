terraform {

  required_version = "1.7.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.45.0"
    }
  }

  backend "azurerm" {}

}

provider "azurerm" {
  skip_provider_registration = "true"
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}
