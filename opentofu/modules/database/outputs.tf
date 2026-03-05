output "postgres_server_id" {
  description = "Resource ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.id
}

output "postgres_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server — use as DB_HOST in backend."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_server_name" {
  description = "Name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.name
}

output "database_name" {
  description = "Name of the application database (tododb)."
  value       = azurerm_postgresql_flexible_server_database.tododb.name
}

output "private_dns_zone_id" {
  description = "ID of the PostgreSQL Private DNS Zone."
  value       = azurerm_private_dns_zone.postgres.id
}

output "connection_string" {
  description = "PostgreSQL connection string (without password — inject via env var)."
  value       = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.tododb.name}?sslmode=require"
  sensitive   = true
}
