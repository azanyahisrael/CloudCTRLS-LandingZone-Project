# Service control policies (ADR-0009). They cap what any identity in a member account can
# do, admins included; they grant nothing.

# Existed before this project's Terraform and was imported unchanged. Attached at the root so
# every member account is covered.
data "aws_iam_policy_document" "deny_leave" {
  statement {
    effect    = "Deny"
    actions   = ["organizations:LeaveOrganization", "account:CloseAccount"]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "deny_leave" {
  name        = "DenyLeaveAndCloseAccount"
  description = "Prevents member accounts from leaving the organization and self closure"
  content     = data.aws_iam_policy_document.deny_leave.json
}

resource "aws_organizations_policy_attachment" "deny_leave" {
  policy_id = aws_organizations_policy.deny_leave.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}

# Everything outside the allowed regions is denied except global services, which AWS serves from
# us-east-1. List based on the AWS example SCP "Deny access to AWS based on the requested Region".
data "aws_iam_policy_document" "region_lock" {
  statement {
    effect = "Deny"
    not_actions = [
      "account:*", "acm:*", "aws-marketplace-management:*", "aws-marketplace:*", "aws-portal:*",
      "billing:*", "budgets:*", "ce:*", "cloudfront:*", "cur:*", "directconnect:*",
      "ec2:DescribeRegions", "ec2:DescribeTransitGateways", "ec2:DescribeVpnGateways",
      "fms:*", "freetier:*", "globalaccelerator:*", "health:*", "iam:*", "invoicing:*",
      "networkmanager:*", "organizations:*", "payments:*", "pricing:*", "route53:*",
      "route53domains:*", "s3:GetAccountPublic*", "s3:ListAllMyBuckets",
      "s3:ListMultiRegionAccessPoints", "s3:PutAccountPublic*", "shield:*", "sts:*",
      "support:*", "tax:*", "trustedadvisor:*", "waf-regional:*", "waf:*", "wafv2:*",
      "wellarchitected:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
}

# Creating and changing these services stays allowed (Step 3.5 builds them); only switching
# them off is denied. Tearing them down means detaching this SCP first, as the management account.
data "aws_iam_policy_document" "protect_security" {
  statement {
    effect = "Deny"
    actions = [
      "cloudtrail:DeleteTrail", "cloudtrail:StopLogging",
      "config:DeleteConfigurationRecorder", "config:DeleteDeliveryChannel", "config:StopConfigurationRecorder",
      "guardduty:DeleteDetector", "guardduty:DisassociateFromAdministratorAccount", "guardduty:DisassociateFromMasterAccount",
    ]
    resources = ["*"]
  }
}

locals {
  project_scps = {
    "region-lock"               = data.aws_iam_policy_document.region_lock.json
    "protect-security-services" = data.aws_iam_policy_document.protect_security.json
  }
}

resource "aws_organizations_policy" "project" {
  for_each = local.project_scps

  name    = each.key
  content = each.value
}

# On ou-cloudctrls, like the Azure baseline on mg-cloudctrls, so every CloudCTRLS environment inherits them.
resource "aws_organizations_policy_attachment" "project" {
  for_each = local.project_scps

  policy_id = aws_organizations_policy.project[each.key].id
  target_id = aws_organizations_organizational_unit.project.id
}
