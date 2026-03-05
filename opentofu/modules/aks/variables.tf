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
  description = "Resource ID of the VNet — used for DNS zone link and Network Contributor role."
  type        = string
}

variable "aks_system_subnet_id" {
  description = "Subnet ID for AKS system node pool (10.0.1.0/24)."
  type        = string
}

variable "aks_user_subnet_id" {
  description = "Subnet ID for AKS user node pool (10.0.2.0/24)."
  type        = string
}

# ── ACR ───────────────────────────────────────────────────────────────────────
variable "acr_id" {
  description = "Resource ID of the ACR — used for AcrPull role assignment on kubelet identity."
  type        = string
}

# ── Node Pool ─────────────────────────────────────────────────────────────────
variable "kubernetes_version" {
  description = "Kubernetes version for the cluster. Leave null for latest stable."
  type        = string
  default     = null
}

variable "system_vm_size" {
  description = "VM SKU for the system node pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "system_node_count" {
  description = "Number of nodes in the system pool."
  type        = number
  default     = 2
}

variable "user_vm_size" {
  description = "VM SKU for the user (workload) node pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "user_node_count" {
  description = "Number of nodes in the user pool."
  type        = number
  default     = 2
}

# ── SSH ───────────────────────────────────────────────────────────────────────
variable "admin_username" {
  description = "Linux admin username for AKS nodes."
  type        = string
  default     = "aksadmin"
}

variable "ssh_public_key" {
  description = "SSH public key for AKS node access."
  type        = string
  sensitive   = true
}
