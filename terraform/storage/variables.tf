variable "storage_account_count" {
  description = "How many storage accounts to create. Increase to add, decrease to remove."
  type        = number
  default     = 1

  validation {
    condition     = var.storage_account_count >= 1 && var.storage_account_count <= 10
    error_message = "storage_account_count must be between 1 and 10"
  }
}

variable "project" {
  description = "Project name — used in resource names and tags"
  type        = string
  default     = "devops-demo"
}

variable "environment" {
  description = "Deployment environment: dev, staging, prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod"
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "account_tier" {
  description = "Standard (general purpose) or Premium (high-performance SSD)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium"
  }
}

variable "replication_type" {
  description = "LRS (cheapest, 1 region), GRS (geo-redundant, 2 regions), ZRS (zone-redundant), RAGRS (read-access geo)"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Invalid replication type"
  }
}

variable "containers" {
  description = "List of blob container names to create inside the storage account"
  type        = list(string)
  default     = ["uploads", "backups", "logs"]
}

variable "enable_versioning" {
  description = "Keep previous versions of overwritten blobs"
  type        = bool
  default     = true
}

variable "soft_delete_days" {
  description = "Number of days deleted blobs/containers are recoverable"
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_days >= 1 && var.soft_delete_days <= 365
    error_message = "soft_delete_days must be between 1 and 365"
  }
}

variable "blob_delete_after_days" {
  description = "Permanently delete blobs after this many days (lifecycle policy)"
  type        = number
  default     = 365
}
