# ─────────────────────────────────────────────────────────────────────────────
#  Root: main.tf
#  Creates the Resource Group and calls the networking module.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
  })
}

# ── Resource Group ─────────────────────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ── Networking Module ──────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  prefix              = local.prefix

  vnet_address_space     = var.vnet_address_space
  aks_system_subnet_cidr = var.aks_system_subnet_cidr
  aks_user_subnet_cidr   = var.aks_user_subnet_cidr
  acr_subnet_cidr        = var.acr_subnet_cidr
  management_subnet_cidr = var.management_subnet_cidr

  tags = local.common_tags
}
