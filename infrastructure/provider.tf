terraform {
  backend "s3" {
    bucket         = "grocery-shop-tfstate-2b1f697b"
    key            = "grocery-shop/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}