terraform {
  backend "s3" {
    bucket          = "aws-grocery-tfstate-backend-200226"
    key             = "global/s3/terraform.tfstate"
    region          = "eu-central-1"
    dynamodb_table  = "terraform-state-locking"
    encrypt         = true
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

# S3 Bucket for backend
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name
  force_destroy = true
}

# versioning
resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table for locking
resource "aws_dynamodb_table" "terraform_locks" {
  name          = var.dynamodb_table_name
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "aws-shop-vpc"
  }
}

# internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "aws-shop-igw"
  }
}

# public subnet
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "aws-shop-public-subnet"
  }
}

# security group
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "allows HTTP & SSH access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["79.243.15.72/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-shop-sg"
  }
}


# DB subnets
resource "aws_subnet" "db_subnet_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "aws-shop-private-subnet-a"
  }
}

resource "aws_subnet" "db_subnet_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "aws-shop-private-subnet-b"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "aws-shop-db-subnet-group"
  subnet_ids = [aws_subnet.db_subnet_a.id, aws_subnet.db_subnet_b.id]
  tags = {
    Name = "aws-shop-db-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "aws-shop-rds-sg"
  description = "allows connection from EC2 to RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-shop-rds-sg"
  }
}

resource "aws_db_instance" "aws_shop_db" {
  instance_class = "db.t3.micro"
  allocated_storage = 20
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "17.6"

  db_name = "aws_shop_db"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
  multi_az = false

  tags = {
    Name = "aws-shop-postgres-db"
  }
}

resource "aws_instance" "grocery-shop-webserver" {
  ami = "ami-0bae57ee7c4478e01"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name = "masterschool-cloud-course"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker postgresql15
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              EOF

  tags = {
    Name = "grocery-shop-webserver"
  }
}