# 1 resource create azrue resource group 
resource "azurerm_resource_group" "tf-rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

