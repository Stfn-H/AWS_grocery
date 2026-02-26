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