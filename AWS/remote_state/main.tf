# ------------------------------------------------------------------------------
# TERRAFORM SETTINGS
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# ------------------------------------------------------------------------------
# AWS PROVIDER (UPDATED REGION)
# ------------------------------------------------------------------------------

provider "aws" {
  region = "eu-north-1"   # Stockholm
}

# ------------------------------------------------------------------------------
# GET ACCOUNT ID
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ------------------------------------------------------------------------------
# CREATE S3 BUCKET
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.account_id}-terraform-states"

  tags = {
    Name = "Terraform State Bucket"
  }
}

# ------------------------------------------------------------------------------
# ENABLE VERSIONING
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------
# ENABLE ENCRYPTION
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ------------------------------------------------------------------------------
# BLOCK PUBLIC ACCESS (SECURITY 🔥)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# CREATE DYNAMODB TABLE
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table"
  }
}
