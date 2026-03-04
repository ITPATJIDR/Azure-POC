# ─── Project ──────────────────────────────────────────────────────────────────
variable "project_name" {
  description = "Short project name, used as prefix for all resources."
  type        = string
  default     = "scg"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

# ─── Azure Location ───────────────────────────────────────────────────────────
variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "southeastasia"
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to create."
  type        = string
  default     = "scg-dev-rg"
}

# ─── Tags ─────────────────────────────────────────────────────────────────────
variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    Project     = "scg-devops"
    ManagedBy   = "opentofu"
    Environment = "dev"
  }
}

# ─── Networking ───────────────────────────────────────────────────────────────
variable "vnet_address_space" {
  description = "CIDR block for the virtual network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_system_subnet_cidr" {
  description = "CIDR for AKS system node pool subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "aks_user_subnet_cidr" {
  description = "CIDR for AKS user (workload) node pool subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "acr_subnet_cidr" {
  description = "CIDR for ACR private endpoint subnet."
  type        = string
  default     = "10.0.3.0/24"
}

variable "management_subnet_cidr" {
  description = "CIDR for management / bastion subnet."
  type        = string
  default     = "10.0.4.0/24"
}
