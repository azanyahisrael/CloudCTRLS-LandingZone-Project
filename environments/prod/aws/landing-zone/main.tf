# AWS landing zone, prod (Phase 3, Step 3.4). Owns the CloudCTRLS OU hierarchy, the
# workload account's placement, SCPs and IAM Identity Center access (ADR-0009).
# Runs as the management account; SCPs never apply to the management account itself.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # The state bucket lives in the workload account and S3 buckets cannot move between
  # accounts, so the backend signs in there while the provider below uses the management account.
  backend "s3" {
    bucket       = "s3-cloudctrls-tfstate-prod-us-west-2-ctrl1"
    key          = "prod/aws/landing-zone.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
    profile      = "cloudctrls-prod"
  }
}

provider "aws" {
  region  = var.region
  profile = "cloudctrls-mgmt"

  default_tags {
    tags = module.naming.tags
  }
}

module "naming" {
  source = "../../../../modules/shared/naming"

  cloud   = "aws"
  env     = var.env
  region  = var.region
  purpose = "landingzone"
}

data "aws_organizations_organization" "this" {}

locals {
  workload_account = one([for a in data.aws_organizations_organization.this.accounts : a if a.id == var.workload_account_id])
}

# Mirrors mg-cloudctrls / mg-cloudctrls-prod in Azure (ADR-0007).
resource "aws_organizations_organizational_unit" "project" {
  name      = "ou-${var.project}"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "env" {
  name      = module.naming.organizational_unit
  parent_id = aws_organizations_organizational_unit.project.id
}

# Imported, not created. Destroying this resource would remove the account from the Organization.
resource "aws_organizations_account" "workload" {
  name      = local.workload_account.name
  email     = local.workload_account.email
  parent_id = aws_organizations_organizational_unit.env.id

  lifecycle {
    prevent_destroy = true
    # Only used when AWS creates an account; unknown for an imported one.
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}
