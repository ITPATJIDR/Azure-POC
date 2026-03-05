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

variable "vnet_id" {
  description = "Resource ID of the VNet — used for DNS zone link."
  type        = string
}

variable "acr_subnet_id" {
  description = "Subnet ID for the ACR private endpoint (acr-subnet, 10.0.3.0/24)."
  type        = string
}
