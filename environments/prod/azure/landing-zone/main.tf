# Azure landing zone, prod (Phase 3). Owns the CloudCTRLS management group hierarchy and
# the dedicated prod subscription (ADR-0007). Policy baseline is added in Step 3.2c.

terraform {
  required_version = ">= 1.10"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-cloudctrls-tfstate-prod-eastus"
    storage_account_name = "stcloudctrlstfstatectrl1"
    container_name       = "tfstate"
    key                  = "prod/azure/landing-zone.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {
    subscription {
      # `terraform destroy` must never cancel the subscription and everything in it.
      prevent_cancellation_on_destroy = true
    }
  }
  # Management groups and subscriptions are tenant-level, but the provider still needs a
  # subscription to run in: the one that currently holds the state backend.
  subscription_id = var.subscription_id
}

module "naming" {
  source = "../../../../modules/shared/naming"

  cloud   = "azure"
  env     = var.env
  region  = var.location
  purpose = "landingzone"
}

# No parent: created directly under the Tenant Root Group, independent of mg-learning-lab.
resource "azurerm_management_group" "project" {
  name         = "mg-${var.project}"
  display_name = "mg-${var.project}"
}

resource "azurerm_management_group" "env" {
  name                       = module.naming.management_group
  display_name               = module.naming.management_group
  parent_management_group_id = azurerm_management_group.project.id

  # Membership is managed by the association below; two owners would fight over it.
  lifecycle {
    ignore_changes = [subscription_ids]
  }
}

resource "azurerm_subscription" "env" {
  alias             = module.naming.subscription
  subscription_name = module.naming.subscription
  billing_scope_id  = var.billing_scope_id
  workload          = "Production"
  tags              = module.naming.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_management_group_subscription_association" "env" {
  management_group_id = azurerm_management_group.env.id
  subscription_id     = "/subscriptions/${azurerm_subscription.env.subscription_id}"
}

# The Azure-Sub-lab01 budget cannot see this subscription, so it gets its own.
resource "azurerm_consumption_budget_subscription" "env" {
  name            = "budget-${var.project}-${var.env}"
  subscription_id = "/subscriptions/${azurerm_subscription.env.subscription_id}"
  amount          = var.monthly_budget
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  # Same thresholds as the existing budgets (Phase 2, Step 2). Owners are notified by role,
  # so no email address is stored in code.
  dynamic "notification" {
    for_each = { "50" = "Actual", "80" = "Actual", "100" = "Forecasted" }

    content {
      threshold      = tonumber(notification.key)
      threshold_type = notification.value
      operator       = "GreaterThanOrEqualTo"
      contact_roles  = ["Owner"]
    }
  }
}
