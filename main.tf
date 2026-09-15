terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Utilisation d'une version stable
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Récupération des infos de ton compte Azure CLI courant (pour le Key Vault)
data "azurerm_client_config" "current" {}

# Le Resource Group qui contiendra tout le projet
resource "azurerm_resource_group" "rg_runops" {
  name     = "rg-protfolio-test"
  location = "France Central"
}