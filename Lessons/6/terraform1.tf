terraform {
    #...
}

provider "azurerm" {
    #...
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-modeldata-prod-001"
  location = "Australia East"
}

resource "azurerm_storage_account" "storageaccount" {
  name                     = "stmodeldataprod001"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}