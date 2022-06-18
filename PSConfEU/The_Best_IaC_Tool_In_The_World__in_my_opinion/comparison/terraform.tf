provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

variable "location" {
  type        = string
  description = "Azure Region Location"
  default = "switzerlandnorth"
}
 
variable "resource_group" {
  type        = string
  description = "Resource Group Name"
  default = "tf-static-web-app"
}
 
variable "storage_account" {
  type        = string
  description = "Storage Account Name"
  default = "rbtfstweb"
}
 
data "azurerm_client_config" "current" {}
 
#Create Resource Group
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group
  location = var.location
}
 
#Create Storage account
resource "azurerm_storage_account" "storage_account" {
  name                = var.storage_account
  resource_group_name = azurerm_resource_group.resource_group.name
 
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
 
  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}
 
#Add html files to blob storage
resource "azurerm_storage_blob" "html_files" {
  for_each = toset( [ "index.html", "404.html" ])

  name                   = each.key
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "./www/${each.key}"
}

#Add png files to blob storage
resource "azurerm_storage_blob" "png_files" {
  for_each = toset( [ "favicon.png" ])

  name                   = each.key
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "image/png"
  source                 = "./www/${each.key}"
}

output "test" {
    value = azurerm_storage_account.storage_account.primary_web_endpoint
}

output "primarykey" {
    value = azurerm_storage_account.storage_account.primary_access_key
}