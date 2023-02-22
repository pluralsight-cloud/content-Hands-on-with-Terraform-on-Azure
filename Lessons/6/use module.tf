module "storageaccount" {
  source                           = "./storage-account"
  storage_account_replication_type = "GRS"
}
