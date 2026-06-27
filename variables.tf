variable "storage_account_count" {
  description = "Number of storage accounts to create"
  type        = number
  default     = 1
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

# Resource group variables

variable "resource_group_name" {
  description = "This is name of resource group"
  type        = string
  //  default = terraform-rg
}


# Resource group location variables

variable "resource_group_location" {
  description = "This is location of resource group"
  type        = string
  // default = eastus
}

