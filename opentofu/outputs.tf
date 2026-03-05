# ─── Resource Group ─────────────────────────────────────────────────────────────
output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region where resources are deployed."
  value       = azurerm_resource_group.main.location
}

# ── Networking ─────────────────────────────────────────────────────────────────
output "vnet_id" {
  description = "Resource ID of the VNet."
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the VNet."
  value       = module.networking.vnet_name
}

output "aks_system_subnet_id" { value = module.networking.aks_system_subnet_id }
output "aks_user_subnet_id" { value = module.networking.aks_user_subnet_id }
output "acr_subnet_id" { value = module.networking.acr_subnet_id }
output "management_subnet_id" { value = module.networking.management_subnet_id }
output "database_subnet_id" { value = module.networking.database_subnet_id }
output "aks_nsg_id" { value = module.networking.aks_nsg_id }
output "management_nsg_id" { value = module.networking.management_nsg_id }
output "database_nsg_id" { value = module.networking.database_nsg_id }

# ── ACR ────────────────────────────────────────────────────────────────────────
output "acr_login_server" {
  description = "ACR login server — use in docker push / Kubernetes imagePullPolicy."
  value       = module.acr.acr_login_server
}

output "acr_name" {
  description = "ACR registry name."
  value       = module.acr.acr_name
}

# ── Load Balancer ──────────────────────────────────────────────────────────────
output "lb_public_ip" {
  description = "Public IP address of the Azure Load Balancer — use for DNS A record."
  value       = module.loadbalancer.public_ip_address
}

output "lb_fqdn" {
  description = "FQDN of the load balancer public IP."
  value       = module.loadbalancer.fqdn
}

# ── AKS ────────────────────────────────────────────────────────────────────────
output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "AKS API server FQDN."
  value       = module.aks.cluster_fqdn
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity."
  value       = module.aks.oidc_issuer_url
}

output "aks_node_resource_group" {
  description = "MC_ resource group containing AKS infrastructure."
  value       = module.aks.node_resource_group
}

output "kube_config_command" {
  description = "Command to download kubeconfig."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}

# ── Database ───────────────────────────────────────────────────────────────────
output "postgres_fqdn" {
  description = "PostgreSQL Flexible Server FQDN — set as DB_HOST in backend."
  value       = module.database.postgres_fqdn
}

output "postgres_database_name" {
  description = "Database name (tododb)."
  value       = module.database.database_name
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string (password not included)."
  value       = module.database.connection_string
  sensitive   = true
}
