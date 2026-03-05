variable "prefix" {
  description = "Resource name prefix."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# ── Networking ────────────────────────────────────────────────────────────────
variable "vnet_id" {
  description = "Resource ID of the VNet — used for Private DNS Zone VNet link."
  type        = string
}

variable "database_subnet_id" {
  description = "Subnet ID for PostgreSQL Flexible Server (delegated, 10.0.5.0/24)."
  type        = string
}

# ── PostgreSQL ────────────────────────────────────────────────────────────────
variable "db_admin_login" {
  description = "Administrator login name for PostgreSQL Flexible Server."
  type        = string
  default     = "todoadmin"
}

variable "db_admin_password" {
  description = "Administrator password for PostgreSQL Flexible Server."
  type        = string
  sensitive   = true
}

variable "db_sku_name" {
  description = "SKU name (e.g. 'B_Standard_B1ms' for dev, 'GP_Standard_D2s_v3' for prod)."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  description = "Storage in MB for PostgreSQL Flexible Server."
  type        = number
  default     = 32768 # 32 GB
}
