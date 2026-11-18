# Naming and tagging convention for every CloudCTRLS resource (ADR-0006).
# Pattern: <type>-<project>-<purpose>-<env>-<region>, e.g. rg-cloudctrls-tfstate-prod-eastus.
# Modules prefix `base` with the resource-type abbreviation (vnet-, kv-, nsg-, ...).
# Types with special naming rules get their own output.

locals {
  base = "${var.project}-${var.purpose}-${var.env}-${var.region}"

  # Storage accounts: lowercase letters and digits only, 3 to 24 characters, globally unique.
  storage_account = "st${var.project}${replace(var.purpose, "-", "")}${var.name_suffix}"

  tags = {
    project    = var.project
    env        = var.env
    cloud      = var.cloud
    region     = var.region
    purpose    = var.purpose
    managed_by = "terraform"
  }
}
