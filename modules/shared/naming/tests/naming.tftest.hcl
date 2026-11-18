# Run from modules/shared/naming:  terraform init && terraform test
# Plan-only tests: no cloud credentials needed, nothing is created.

run "matches_azure_bootstrap" {
  command = plan

  variables {
    cloud       = "azure"
    env         = "prod"
    region      = "eastus"
    purpose     = "tfstate"
    name_suffix = "ctrl1"
  }

  assert {
    condition     = output.resource_group == "rg-cloudctrls-tfstate-prod-eastus"
    error_message = "Resource group name does not match the deployed Azure bootstrap."
  }

  assert {
    condition     = output.storage_account == "stcloudctrlstfstatectrl1"
    error_message = "Storage account name does not match the deployed Azure bootstrap."
  }

  assert {
    condition     = output.tags.cloud == "azure" && output.tags.managed_by == "terraform"
    error_message = "Standard tags are missing or wrong."
  }
}

run "matches_aws_bootstrap" {
  command = plan

  variables {
    cloud       = "aws"
    env         = "prod"
    region      = "us-west-2"
    purpose     = "tfstate"
    name_suffix = "ctrl1"
  }

  assert {
    # Must match the bucket deployed by bootstrap/aws (Phase 2, Step 4b).
    condition     = output.s3_bucket == "s3-cloudctrls-tfstate-prod-us-west-2-ctrl1"
    error_message = "S3 bucket name does not match the deployed AWS bootstrap."
  }
}

run "rejects_unknown_env" {
  command = plan

  variables {
    cloud   = "azure"
    env     = "qa"
    region  = "eastus"
    purpose = "app"
  }

  expect_failures = [var.env]
}

run "rejects_too_long_storage_account" {
  command = plan

  variables {
    cloud       = "azure"
    env         = "prod"
    region      = "eastus"
    purpose     = "centralizedlogging"
    name_suffix = "ctrl1"
  }

  expect_failures = [output.storage_account]
}
