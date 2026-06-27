resource "azurerm_storage_account" "TF-storage" {
  count                    = var.storage_account_count
  name                     = "addtfstr123${count.index}"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "tf-ss-container" {
  count                 = var.storage_account_count
  name                  = "tf-container${count.index}"
  storage_account_name  = azurerm_storage_account.TF-storage[count.index].name
  container_access_type = "private"
}
