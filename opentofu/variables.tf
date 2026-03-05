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
  description = "CIDR for AKS system node pool subnet (Tier 1+2 infrastructure)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "aks_user_subnet_cidr" {
  description = "CIDR for AKS user (workload) node pool subnet (Tier 1+2 application)."
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

variable "database_subnet_cidr" {
  description = "CIDR for the PostgreSQL database subnet (Tier 3). Port 5432 restricted to AKS subnets only."
  type        = string
  default     = "10.0.5.0/24"
}

# ─── AKS ──────────────────────────────────────────────────────────────────────
variable "kubernetes_version" {
  description = "Kubernetes version. null = latest stable."
  type        = string
  default     = null
}

variable "aks_system_vm_size" {
  description = "VM SKU for AKS system node pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_system_node_count" {
  description = "Node count for AKS system pool."
  type        = number
  default     = 2
}

variable "aks_user_vm_size" {
  description = "VM SKU for AKS user (workload) node pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_user_node_count" {
  description = "Node count for AKS user pool."
  type        = number
  default     = 2
}

variable "aks_admin_username" {
  description = "Linux admin username for AKS nodes."
  type        = string
  default     = "aksadmin"
}

variable "ssh_public_key" {
  description = "SSH public key for AKS node access. Required for apply."
  type        = string
  sensitive   = true
}

# ─── Database ─────────────────────────────────────────────────────────────────
variable "db_admin_login" {
  description = "PostgreSQL administrator login."
  type        = string
  default     = "todoadmin"
}

variable "db_admin_password" {
  description = "PostgreSQL administrator password. Must meet Azure complexity requirements."
  type        = string
  sensitive   = true
}

variable "db_sku_name" {
  description = "PostgreSQL Flexible Server SKU. Use B_Standard_B1ms for dev, GP_Standard_D2s_v3 for prod."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  description = "Storage allocated to PostgreSQL Flexible Server in MB."
  type        = number
  default     = 32768
}
