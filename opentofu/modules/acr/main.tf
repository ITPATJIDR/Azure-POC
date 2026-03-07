# ─────────────────────────────────────────────────────────────────────────────
#  modules/acr/main.tf
#  Azure Container Registry (Premium) + Private Endpoint + Private DNS Zone
# ─────────────────────────────────────────────────────────────────────────────

# ── Azure Container Registry ──────────────────────────────────────────────────
resource "azurerm_container_registry" "main" {
  name                = replace("${var.prefix}acr", "-", "") # ACR name: alphanumeric only
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium" # Required for private link

  admin_enabled                 = true  # Enable admin for easier testing/fallback if needed
  public_network_access_enabled = true  # Allow GitHub Actions to reach the registry
  zone_redundancy_enabled       = false # Set true for production HA

  network_rule_set {
    default_action = "Allow"
  }

  tags = var.tags
}

# ── Private DNS Zone for ACR ──────────────────────────────────────────────────
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "${var.prefix}-acr-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# ── Private Endpoint for ACR ──────────────────────────────────────────────────
resource "azurerm_private_endpoint" "acr" {
  name                = "${var.prefix}-acr-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.acr_subnet_id

  private_service_connection {
    name                           = "${var.prefix}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  tags = var.tags
}
