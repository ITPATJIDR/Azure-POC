# ─────────────────────────────────────────────────────────────────────────────
#  Root: main.tf
#  Three-Tier Architecture: Networking → ACR → Load Balancer → AKS → Database
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

# ── Tier 0: Networking (VNet + Subnets + NSGs) ────────────────────────────────
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
  database_subnet_cidr   = var.database_subnet_cidr

  tags = local.common_tags
}

# ── ACR (Azure Container Registry) ───────────────────────────────────────────
# Must be created before AKS so the AcrPull role assignment has a valid ACR ID
module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  prefix              = local.prefix

  vnet_id       = module.networking.vnet_id
  acr_subnet_id = module.networking.acr_subnet_id

  tags = local.common_tags

  depends_on = [module.networking]
}

# ── Load Balancer (Public IP + Standard Azure LB) ─────────────────────────────
module "loadbalancer" {
  source = "./modules/loadbalancer"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  prefix              = local.prefix

  dns_label = "${local.prefix}-app"

  tags = local.common_tags

  depends_on = [module.networking]
}

# ── Tier 1 + 2: AKS (Presentation + Application tiers) ───────────────────────
module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  prefix              = local.prefix

  # VNet integration
  vnet_id              = module.networking.vnet_id
  aks_system_subnet_id = module.networking.aks_system_subnet_id
  aks_user_subnet_id   = module.networking.aks_user_subnet_id

  # ACR pull permission
  acr_id = module.acr.acr_id

  # Node pools
  kubernetes_version = var.kubernetes_version
  system_vm_size     = var.aks_system_vm_size
  system_node_count  = var.aks_system_node_count
  user_vm_size       = var.aks_user_vm_size
  user_node_count    = var.aks_user_node_count

  # SSH access
  admin_username = var.aks_admin_username
  ssh_public_key = var.ssh_public_key

  tags = local.common_tags

  depends_on = [module.networking, module.acr]
}

# ── Tier 3: Database (PostgreSQL Flexible Server) ─────────────────────────────
module "database" {
  source = "./modules/database"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  prefix              = local.prefix

  # VNet integration
  vnet_id            = module.networking.vnet_id
  database_subnet_id = module.networking.database_subnet_id

  # PostgreSQL credentials
  db_admin_login    = var.db_admin_login
  db_admin_password = var.db_admin_password
  db_sku_name       = var.db_sku_name
  db_storage_mb     = var.db_storage_mb

  tags = local.common_tags

  depends_on = [module.networking]
}
