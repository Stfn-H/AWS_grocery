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
    docker run -d --network host\
      -e S3_BUCKET_NAME=${aws_s3_bucket.avatars.id} \
      -e S3_REGION=${var.aws_region} \
      -e USE_S3_STORAGE=true \
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