output "storage_account_names" {
  description = "Names of all created storage accounts (one per count index)"
  value       = [for sa in azurerm_storage_account.main : sa.name]
}

output "storage_account_ids" {
  description = "Resource IDs of all storage accounts"
  value       = [for sa in azurerm_storage_account.main : sa.id]
}

output "primary_blob_endpoints" {
  description = "Blob endpoints for each storage account"
  value       = [for sa in azurerm_storage_account.main : sa.primary_blob_endpoint]
}

output "primary_connection_strings" {
  description = "Connection strings for each storage account (sensitive)"
  value       = [for sa in azurerm_storage_account.main : sa.primary_connection_string]
  sensitive   = true
}

output "containers" {
  description = "All containers created, grouped by storage account index"
  value = {
    for idx in range(var.storage_account_count) :
    azurerm_storage_account.main[idx].name => [
      for k, v in azurerm_storage_container.containers :
      v.name if startswith(k, "${idx}-")
    ]
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.storage.name
}
