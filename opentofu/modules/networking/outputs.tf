# ── VNet ──────────────────────────────────────────────────────────────────────
output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.main.name
}

# ── Subnet IDs ────────────────────────────────────────────────────────────────
output "aks_system_subnet_id" {
  description = "Subnet ID for AKS system node pool. Pass to azurerm_kubernetes_cluster default_node_pool.vnet_subnet_id."
  value       = azurerm_subnet.aks_system.id
}

output "aks_user_subnet_id" {
  description = "Subnet ID for AKS user node pool. Pass to azurerm_kubernetes_cluster_node_pool.vnet_subnet_id."
  value       = azurerm_subnet.aks_user.id
}

output "acr_subnet_id" {
  description = "Subnet ID for ACR Private Endpoint. Pass to azurerm_private_endpoint.subnet_id."
  value       = azurerm_subnet.acr.id
}

output "management_subnet_id" {
  description = "Subnet ID for management / bastion host."
  value       = azurerm_subnet.management.id
}

output "database_subnet_id" {
  description = "Subnet ID for PostgreSQL database (Tier 3). Pass to azurerm_postgresql_flexible_server or private endpoint."
  value       = azurerm_subnet.database.id
}

# ── NSG IDs ───────────────────────────────────────────────────────────────────
output "aks_nsg_id" {
  description = "ID of the NSG associated with AKS subnets."
  value       = azurerm_network_security_group.aks.id
}

output "management_nsg_id" {
  description = "ID of the NSG associated with the management subnet."
  value       = azurerm_network_security_group.management.id
}

output "database_nsg_id" {
  description = "ID of the NSG associated with the database subnet. Allows port 5432 from AKS and management subnets only."
  value       = azurerm_network_security_group.database.id
}
