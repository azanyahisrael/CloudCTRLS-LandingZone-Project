# Central logging (Step 3.3): one Log Analytics workspace receiving the subscription
# activity log and access logs for the Terraform state storage.

module "naming_logging" {
  source = "../../../../modules/shared/naming"

  cloud   = "azure"
  env     = var.env
  region  = var.location
  purpose = "logging"
}

# Same inputs as bootstrap/azure, so these names match the deployed state backend (covered by tests).
module "naming_tfstate" {
  source = "../../../../modules/shared/naming"

  cloud       = "azure"
  env         = var.env
  region      = var.location
  purpose     = "tfstate"
  name_suffix = "ctrl1"
}

resource "azurerm_resource_group" "logging" {
  name     = module.naming_logging.resource_group
  location = var.location
  tags     = module.naming_logging.tags
}

resource "azurerm_log_analytics_workspace" "central" {
  name                = "log-${module.naming_logging.base}"
  location            = azurerm_resource_group.logging.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  # shortcut: hard cap keeps ingestion inside the 5 GB/month free allowance but drops logs
  # for the rest of the day once reached; raise or remove when real workloads log here.
  daily_quota_gb = 0.15

  tags = module.naming_logging.tags
}

# Every create, change and delete in the subscription (ingestion of this table is free).
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "diag-${module.naming_logging.base}"
  target_resource_id         = "/subscriptions/${azurerm_subscription.env.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  dynamic "enabled_log" {
    for_each = ["Administrative", "Security", "ServiceHealth", "Alert", "Recommendation", "Policy", "Autoscale", "ResourceHealth"]

    content {
      category = enabled_log.value
    }
  }
}

# Who read, wrote or deleted Terraform state, which can contain secrets.
resource "azurerm_monitor_diagnostic_setting" "tfstate_blobs" {
  name                       = "diag-${module.naming_logging.base}"
  target_resource_id         = "/subscriptions/${azurerm_subscription.env.subscription_id}/resourceGroups/${module.naming_tfstate.resource_group}/providers/Microsoft.Storage/storageAccounts/${module.naming_tfstate.storage_account}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  dynamic "enabled_log" {
    for_each = ["StorageRead", "StorageWrite", "StorageDelete"]

    content {
      category = enabled_log.value
    }
  }
}
