# ── Resource Group ─────────────────────────────────────────────────────────────
output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "Resource ID of the resource group."
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Azure region where resources are deployed."
  value       = azurerm_resource_group.main.location
}

# ── Networking (pass-through from module) ─────────────────────────────────────
output "vnet_id" {
  description = "Resource ID of the VNet. Use when attaching AKS or other resources."
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the VNet."
  value       = module.networking.vnet_name
}

output "aks_system_subnet_id" {
  description = "Subnet ID for AKS system node pool — pass to azurerm_kubernetes_cluster."
  value       = module.networking.aks_system_subnet_id
}

output "aks_user_subnet_id" {
  description = "Subnet ID for AKS user (workload) node pool."
  value       = module.networking.aks_user_subnet_id
}

output "acr_subnet_id" {
  description = "Subnet ID for ACR private endpoint."
  value       = module.networking.acr_subnet_id
}

output "management_subnet_id" {
  description = "Subnet ID for management / bastion access."
  value       = module.networking.management_subnet_id
}

output "aks_nsg_id" {
  description = "ID of the NSG attached to AKS subnets."
  value       = module.networking.aks_nsg_id
}

output "management_nsg_id" {
  description = "ID of the NSG attached to management subnet."
  value       = module.networking.management_nsg_id
}
