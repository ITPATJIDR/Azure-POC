output "acr_id" {
  description = "Resource ID of the ACR — pass to AKS module for AcrPull role assignment."
  value       = azurerm_container_registry.main.id
}

output "acr_login_server" {
  description = "Login server FQDN (e.g. scgdevacr.azurecr.io)."
  value       = azurerm_container_registry.main.login_server
}

output "acr_name" {
  description = "Name of the ACR."
  value       = azurerm_container_registry.main.name
}

output "private_endpoint_id" {
  description = "Resource ID of the ACR private endpoint."
  value       = azurerm_private_endpoint.acr.id
}
