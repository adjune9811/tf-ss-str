terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  # Remote state — stored in Azure Blob so the pipeline and local machine share the same state
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate001"
    container_name       = "tfstate"
    key                  = "storage/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
  # are injected by the Azure DevOps service connection automatically
}

# ─── Resource Group ───────────────────────────────────────────────────────────
resource "azurerm_resource_group" "storage" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location
  tags     = local.tags
}

# ─── Storage Account ──────────────────────────────────────────────────────────
resource "azurerm_storage_account" "main" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.storage.name
  location            = azurerm_resource_group.storage.location

  account_tier             = var.account_tier             # Standard or Premium
  account_replication_type = var.replication_type         # LRS, GRS, RAGRS, ZRS

  # Security: disable public blob access — blobs are private by default
  allow_nested_items_to_be_public  = false

  # Security: require HTTPS for all requests
  enable_https_traffic_only = true

  # Security: require TLS 1.2 minimum
  min_tls_version = "TLS1_2"

  # Enable blob versioning — keeps previous versions of overwritten blobs
  blob_properties {
    versioning_enabled = var.enable_versioning

    # Soft delete: deleted blobs are recoverable for N days
    delete_retention_policy {
      days = var.soft_delete_days
    }

    # Soft delete for containers too
    container_delete_retention_policy {
      days = var.soft_delete_days
    }
  }

  # Lifecycle: automatically move old blobs to cheaper storage tiers
  # (only works with Standard LRS/GRS, not Premium)
  lifecycle {
    ignore_changes = [
      # Azure may update tags internally — ignore to avoid spurious diffs
      tags["ms-resource-usage"]
    ]
  }

  tags = local.tags
}

# ─── Lifecycle Management Policy ─────────────────────────────────────────────
# Automatically tier blobs to save cost:
#   0–30 days   → Hot (frequent access, higher cost)
#   30–90 days  → Cool (infrequent access, lower cost)
#   90+ days    → Archive (rare access, cheapest)
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "tier-to-cool-then-archive"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
      # Apply to all containers — or specify: prefix_match = ["logs/", "backups/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = var.blob_delete_after_days
      }

      # Also apply to snapshots
      snapshot {
        delete_after_days_since_creation_greater_than = var.soft_delete_days
      }
    }
  }
}

# ─── Storage Containers ───────────────────────────────────────────────────────
# Create one container for each name in var.containers
resource "azurerm_storage_container" "containers" {
  for_each = toset(var.containers)

  name                  = each.value
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"   # never "blob" or "container" — keeps data private
}
