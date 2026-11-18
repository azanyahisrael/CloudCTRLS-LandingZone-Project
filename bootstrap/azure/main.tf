# Bootstrap: Azure Storage backend for Terraform state (ADR-0004).
# Applied once with local state, then its own state is migrated into the
# storage account it creates (see backend block at the bottom).

terraform {
  required_version = ">= 1.10"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  # Shared keys are disabled on the account, so data-plane calls must use Entra ID.
  storage_use_azuread = true
}

data "azurerm_client_config" "current" {}

locals {
  base_name = "${var.project}-tfstate-${var.env}-${var.location}"

  tags = {
    project    = var.project
    env        = var.env
    cloud      = "azure"
    region     = var.location
    purpose    = "tfstate"
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  # Storage account names allow no hyphens and must be globally unique.
  name                     = "st${var.project}tfstate${var.name_suffix}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  account_kind             = "StorageV2"

  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = true

  # shortcut: reachable from the internet (Entra ID auth still required) so the laptop
  # and GitHub-hosted runners can use it; restrict with network rules or a private endpoint in Phase 3/7.
  public_network_access_enabled = true

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.tags
}

# Lets the identity running Terraform read and write state through Entra ID.
resource "azurerm_role_assignment" "tfstate_data" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"

  depends_on = [azurerm_role_assignment.tfstate_data]
}

# Prevents the state storage from being deleted by accident, including by `terraform destroy`.
resource "azurerm_management_lock" "tfstate" {
  name       = "lock-${local.base_name}"
  scope      = azurerm_storage_account.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Holds Terraform state for CloudCTRLS. Remove deliberately before teardown."
}

# This configuration's own state lives in the storage account it creates. The first apply
# used local state, which was then moved here with `terraform init -migrate-state`.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cloudctrls-tfstate-prod-eastus"
    storage_account_name = "stcloudctrlstfstatectrl1"
    container_name       = "tfstate"
    key                  = "bootstrap/azure.tfstate"
    use_azuread_auth     = true
  }
}
