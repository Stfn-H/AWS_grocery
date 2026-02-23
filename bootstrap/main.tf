terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# random hex value
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# s3 bucket for backend
resource "aws_s3_bucket" "terraform_state" {
  bucket = "grocery-shop-tfstate-${random_id.bucket_suffix.hex}"

  lifecycle {
    prevent_destroy = true
  }
}

# s3 versioning
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# s3 Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# bucket name output
output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

# DynamoDB table for locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ECR Repository for Dockerfile
resource "aws_ecr_repository" "app_repo" {
  name                 = "grocery-shop-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}