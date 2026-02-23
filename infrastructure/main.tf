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

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
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
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "aws-shop-public-subnet"
  }
}

# ROute Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "aws-shop-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public.id
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
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "aws-shop-private-subnet-a"
  }
}

resource "aws_subnet" "db_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "aws-shop-private-subnet-b"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "aws-shop-db-subnet-group"
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
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
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
  identifier          = "aws-grocery-db"
  snapshot_identifier = var.db_snapshot_identifier
  instance_class      = "db.t3.micro"
  storage_encrypted   = true #added because it was enabled also in the snapshot

  # not needed while using snapshot
  # allocated_storage = 20
  # storage_type      = "gp2"
  # engine            = "postgres"
  # engine_version    = "17.6"

  # db_name  = "aws_shop_db"
  # username = var.db_username
  # password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
  multi_az            = false

  tags = {
    Name = "aws-shop-postgres-db"
  }
}

# IAM role for EC2 to pull the DOckerfile from ECR
resource "aws_iam_role" "ec2_role" {
  name = "grocery_ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "grocery_ec2_profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance
resource "aws_instance" "grocery-shop-webserver" {
  ami                         = "ami-0bae57ee7c4478e01"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = "masterschool-cloud-course"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl start docker
    systemctl enable docker

    # ECR login on EC2
    aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 156332912416.dkr.ecr.eu-central-1.amazonaws.com

    # Docker image pull
    docker pull 156332912416.dkr.ecr.eu-central-1.amazonaws.com/grocery-shop-repo:latest
    docker run -d --network host \
      -e POSTGRES_USER=${var.db_user} \
      -e POSTGRES_PASSWORD=${var.db_password} \
      -e POSTGRES_HOST=${aws_db_instance.aws_shop_db.address} \
      -e POSTGRES_DB=${var.db_name} \
      -e JWT_SECRET=${var.jwt_secret} \
      -p 5000:5000 \
      156332912416.dkr.ecr.eu-central-1.amazonaws.com/grocery-shop-repo:latest
  EOF


  tags = {
    Name = "grocery-shop-webserver"
  }
}
