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

variable "db_user" {
  description = "DB USername"
  type        = string
  default     = "postgres" # Standardwert, kann so bleiben
}

variable "db_name" {
  description = "DB Name"
  type        = string
  default     = "postgres" # Standardwert
}

variable "db_password" {
  description = "DB Password"
  type        = string
  sensitive   = true # Versteckt die Eingabe im Terminal
}

variable "jwt_secret" {
  description = "secret key"
  type        = string
  sensitive   = true
}

variable "db_snapshot_identifier" {
  description = "snapshot with dummy data: aws-grocery-db-snapshot-v1"
  type        = string
  default     = "aws-grocery-db-snapshot-v1"
}