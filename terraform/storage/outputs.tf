output "storage_account_name" {
  description = "Name of the created storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "primary_blob_endpoint" {
  description = "Blob service endpoint — use this URL to access blobs"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_connection_string" {
  description = "Connection string for apps to connect to this storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true   # marked sensitive — won't print in pipeline logs
}

output "containers" {
  description = "Map of created container names"
  value       = { for k, v in azurerm_storage_container.containers : k => v.name }
}

output "resource_group_name" {
  value = azurerm_resource_group.storage.name
}
