# Bootstrap: S3 backend for AWS Terraform state (ADR-0004).
# Applied once with local state, then its own state is migrated into the
# bucket it creates (see backend block at the bottom).

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Applied to every resource this provider creates.
  default_tags {
    tags = {
      project    = var.project
      env        = var.env
      cloud      = "aws"
      region     = var.region
      purpose    = "tfstate"
      managed_by = "terraform"
    }
  }
}

resource "aws_s3_bucket" "tfstate" {
  # Bucket names are globally unique across all AWS accounts.
  bucket = "s3-${var.project}-tfstate-${var.env}-${var.region}-${var.name_suffix}"

  # Terraform refuses to destroy the bucket that holds its own state.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Disables ACLs so access is controlled only by IAM and the bucket policy.
resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# shortcut: S3-managed keys (SSE-S3); move to a customer-managed KMS key in Phase 3.
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Old state versions are kept 30 days for recovery, matching the Azure soft-delete window.
resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.tfstate]
}

data "aws_iam_policy_document" "tfstate" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.tfstate.arn, "${aws_s3_bucket.tfstate.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.tfstate.json

  # The public access block must exist first or AWS can reject the policy.
  depends_on = [aws_s3_bucket_public_access_block.tfstate]
}

# This configuration's own state lives in the bucket it creates. The first apply
# used local state, which was then moved here with `terraform init -migrate-state`.
terraform {
  backend "s3" {
    bucket       = "s3-cloudctrls-tfstate-prod-us-west-2-ctrl1"
    key          = "bootstrap/aws.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
