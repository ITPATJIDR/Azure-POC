variable "prefix" {
  description = "Resource name prefix (e.g. 'scg-dev')."
  type        = string
}

variable "location" {
  description = "Azure region for networking resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy networking resources into."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all networking resources."
  type        = map(string)
  default     = {}
}

# ── VNet ──────────────────────────────────────────────────────────────────────
variable "vnet_address_space" {
  description = "Address space for the VNet (e.g. ['10.0.0.0/16'])."
  type        = list(string)
}

# ── Subnets ───────────────────────────────────────────────────────────────────
variable "aks_system_subnet_cidr" {
  description = "CIDR for AKS system node pool subnet."
  type        = string
}

variable "aks_user_subnet_cidr" {
  description = "CIDR for AKS user (workload) node pool subnet."
  type        = string
}

variable "acr_subnet_cidr" {
  description = "CIDR for ACR private endpoint subnet."
  type        = string
}

variable "management_subnet_cidr" {
  description = "CIDR for management / bastion subnet."
  type        = string
}

variable "database_subnet_cidr" {
  description = "CIDR for PostgreSQL / database subnet (Tier 3). Only AKS subnets may connect on port 5432."
  type        = string
}

# ── NSG ───────────────────────────────────────────────────────────────────────
variable "management_allowed_cidr" {
  description = "Source CIDR allowed to SSH/RDP into the management subnet. Restrict to your corporate IP or VPN."
  type        = string
  default     = "10.0.0.0/8"
}

