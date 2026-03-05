# ─────────────────────────────────────────────────────────────────────────────
#  modules/database/main.tf
#  PostgreSQL Flexible Server — VNet integration + Private DNS
# ─────────────────────────────────────────────────────────────────────────────

# ── Private DNS Zone for PostgreSQL ──────────────────────────────────────────
resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.prefix}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.prefix}-postgres-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# ── PostgreSQL Flexible Server ────────────────────────────────────────────────
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.prefix}-postgres"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "16"
  administrator_login    = var.db_admin_login
  administrator_password = var.db_admin_password

  # VNet integration — uses delegated database subnet
  # public_network_access MUST be disabled when using delegated subnet VNet integration
  public_network_access_enabled = false
  delegated_subnet_id           = var.database_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id

  # Storage & Compute
  storage_mb = var.db_storage_mb
  sku_name   = var.db_sku_name # e.g. "B_Standard_B1ms" / "GP_Standard_D2s_v3"

  # Availability Zone
  zone = "1"

  # Backup
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  # Maintenance window (Sunday 02:00 Bangkok)
  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# ── Database for Todo App (Tier 3 data) ───────────────────────────────────────
resource "azurerm_postgresql_flexible_server_database" "tododb" {
  name      = "tododb"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# ── PostgreSQL Configurations ─────────────────────────────────────────────────
resource "azurerm_postgresql_flexible_server_configuration" "connection_throttling" {
  name      = "connection_throttle.enable"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_checkpoints" {
  name      = "log_checkpoints"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  name      = "log_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}
