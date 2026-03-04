locals {
  _az = jsondecode(file("${path.module}/az.json"))
}

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # ── Remote Backend (Azure Blob Storage) ───────────────────────────────────
  # Uncomment and fill in after creating storage account:
  #
  # backend "azurerm" {
  #   resource_group_name  = "scg-tfstate-rg"
  #   storage_account_name = "scgtfstate"
  #   container_name       = "tfstate"
  #   key                  = "networking/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}

  client_id       = local._az.appId
  client_secret   = local._az.password
  tenant_id       = local._az.tenant
  subscription_id = local._az.subscriptionId

  skip_provider_registration = true
}
