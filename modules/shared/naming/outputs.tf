output "base" {
  description = "Name body to prefix with a resource-type abbreviation."
  value       = local.base
}

output "resource_group" {
  value = "rg-${local.base}"
}

output "storage_account" {
  value = local.storage_account

  precondition {
    condition     = can(regex("^[a-z0-9]{3,24}$", local.storage_account))
    error_message = "Storage account name must be 3 to 24 lowercase letters or digits. Shorten purpose or name_suffix."
  }
}

# Tenant-level containers have no location, so they stop at the environment.
output "management_group" {
  value = "mg-${var.project}-${var.env}"
}

output "subscription" {
  value = "sub-${var.project}-${var.env}"
}

output "s3_bucket" {
  value = join("-", compact(["s3", local.base, var.name_suffix]))
}

output "tags" {
  value = local.tags
}
