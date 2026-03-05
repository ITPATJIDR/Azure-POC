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

variable "dns_label" {
  description = "DNS label for the public IP (becomes <label>.<region>.cloudapp.azure.com)."
  type        = string
  default     = null
}
