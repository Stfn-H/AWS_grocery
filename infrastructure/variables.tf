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

variable "public_subnet_a_cidr" {
  description = "IP range for public subnet a"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "IP range for public subnet b"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_db_subnet_a" {
  description = "IP range for private db subnet a"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_db_subnet_b" {
  description = "IP range for private db subnet b"
  type        = string
  default     = "10.0.11.0/24"
}

variable "db_user" {
  description = "DB Username"
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