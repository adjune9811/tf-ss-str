terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate001"
    container_name       = "tfstate"
    key                  = "storage/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ─── Resource Group ───────────────────────────────────────────────────────────
resource "azurerm_resource_group" "storage" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location
  tags     = local.tags
}

# ─── Storage Accounts (count) ─────────────────────────────────────────────────
# CONCEPT: count meta-argument
# Creates N copies of this resource — one per index (0, 1, 2 ...).
# To add a storage account:  set storage_account_count = 3  in tfvars → terraform apply
# To remove one:             set storage_account_count = 1  in tfvars → terraform apply
#
# IMPORTANT: count uses index-based addressing:
#   azurerm_storage_account.main[0]  → first account
#   azurerm_storage_account.main[1]  → second account
#
# WARNING: if you remove from the MIDDLE (e.g. index 1 of 3), Terraform
# re-indexes — index 2 becomes index 1 and is REPLACED, not kept.
# Use for_each with a map if order stability matters more than simplicity.
resource "azurerm_storage_account" "main" {
  count = var.storage_account_count

  # Each account gets a unique name: prefix + index (e.g. stdevdemodev0, stdevdemodev1)
  name                = "${local.storage_name_prefix}${count.index}"
  resource_group_name = azurerm_resource_group.storage.name
  location            = azurerm_resource_group.storage.location

  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  blob_properties {
    versioning_enabled = var.enable_versioning

    delete_retention_policy {
      days = var.soft_delete_days
    }

    container_delete_retention_policy {
      days = var.soft_delete_days
    }
  }

  lifecycle {
    ignore_changes = [tags["ms-resource-usage"]]
  }

  tags = merge(local.tags, {
    # Tag each account with its index so you can identify it easily in the portal
    AccountIndex = tostring(count.index)
  })
}

# ─── Lifecycle Management Policy ─────────────────────────────────────────────
# count here mirrors the storage account count — one policy per account.
# count.index is used to reference the matching storage account.
resource "azurerm_storage_management_policy" "lifecycle" {
  count = var.storage_account_count

  # [count.index] links this policy to its storage account
  storage_account_id = azurerm_storage_account.main[count.index].id

  rule {
    name    = "tier-and-expire"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = var.blob_delete_after_days
      }

      snapshot {
        delete_after_days_since_creation_greater_than = var.soft_delete_days
      }
    }
  }
}

# ─── Storage Containers ───────────────────────────────────────────────────────
# CONCEPT: count + for_each combination
# We need containers inside EACH storage account.
# Problem: can't nest count inside for_each.
# Solution: flatten into a single map keyed by "accountIndex-containerName".
#
# Example with count=2, containers=["uploads","logs"]:
#   local.container_map = {
#     "0-uploads" = { account_index = 0, container_name = "uploads" }
#     "0-logs"    = { account_index = 0, container_name = "logs"    }
#     "1-uploads" = { account_index = 1, container_name = "uploads" }
#     "1-logs"    = { account_index = 1, container_name = "logs"    }
#   }
resource "azurerm_storage_container" "containers" {
  for_each = local.container_map

  name                  = each.value.container_name
  storage_account_id    = azurerm_storage_account.main[each.value.account_index].id
  container_access_type = "private"
}
