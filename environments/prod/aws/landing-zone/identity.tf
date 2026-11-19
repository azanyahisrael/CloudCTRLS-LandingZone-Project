# IAM Identity Center access (ADR-0009). The instance, MFA settings and the cloudctrls-admin
# user were set up in the console (enabling an organization instance has no API); the
# permission set and account assignments were imported.

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn  = one(data.aws_ssoadmin_instances.this.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)
  admin_accounts    = toset([data.aws_organizations_organization.this.master_account_id, var.workload_account_id])
}

data "aws_identitystore_user" "admin" {
  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = "cloudctrls-admin"
    }
  }
}

resource "aws_ssoadmin_permission_set" "admin" {
  name             = "AdministratorAccess"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT1H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_account_assignment" "admin" {
  for_each = local.admin_accounts

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_type     = "USER"
  principal_id       = data.aws_identitystore_user.admin.user_id
  target_type        = "AWS_ACCOUNT"
  target_id          = each.key
}
