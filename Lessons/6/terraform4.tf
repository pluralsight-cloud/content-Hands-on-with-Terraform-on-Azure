terraform {
  #...
}

provider "azurerm" {
  #...
}


variable "storage_account_replication_type" {
  type    = string
  default = "LRS"
}

locals {
  workload_name = "modeldata"
  environment   = "prod"
  instance = "001"
}

resource "azurerm_resource_group" "rg" {
  name     =  "rg-${local.workload_name}-${local.workload_name}-${local.instance}"
  location = "Australia East"
}

resource "azurerm_storage_account" "storageaccount" {
  name                     = "st{local.workload_name}${local.workload_name}${local.instance}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = var.storage_account_replication_type
}

output "storage_account_primary_blob_host" {
  value = azurerm_storage_account.storageaccount.primary_blob_host
}