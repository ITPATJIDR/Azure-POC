output "public_ip_address" {
  description = "Public IP address of the load balancer."
  value       = azurerm_public_ip.lb.ip_address
}

output "public_ip_id" {
  description = "Resource ID of the public IP — reference in AKS or Kubernetes Service annotations."
  value       = azurerm_public_ip.lb.id
}

output "lb_id" {
  description = "Resource ID of the Azure Load Balancer."
  value       = azurerm_lb.main.id
}

output "backend_pool_id" {
  description = "ID of the LB backend address pool."
  value       = azurerm_lb_backend_address_pool.main.id
}

output "fqdn" {
  description = "FQDN of the public IP (if dns_label is set)."
  value       = azurerm_public_ip.lb.fqdn
}
