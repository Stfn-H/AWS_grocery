variable "aws_region" {
  description = "the default AWS Region for the resources"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "Default AWS CLI account"
  type        = string
  default     = "AdministratorAccess-156332912416"
}

variable "state_bucket_name" {
  description = "S3 bucket name for terraform backend"
  type        = string
  default     = "aws-grocery-tfstate-backend-200226"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "terraform-state-locking"
}

variable "vpc_cidr" {
  description = "IP range for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IP range for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "db_username" {
  description = "DB admin username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "DB Admin Password"
  type        = string
  sensitive   = true
}

variable "db_snapshot_identifier" {
  description = "snapshot with dummy data: aws-grocery-db-snapshot-v1"
  type        = string
  default     = "aws-grocery-db-snapshot-v1"
}