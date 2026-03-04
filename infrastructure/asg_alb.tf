# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "grocery-shop-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.public-a.id, aws_subnet.public-b.id]
}

# Target-Group
resource "aws_lb_target_group" "grocery-shop-tg" {
  name     = "grocery-shop-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# ALB-Listener
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grocery-shop-tg.arn
  }
}

# Launch-Template
resource "aws_launch_template" "grocery-shop-lt" {
  name_prefix            = "grocery-shop-template-"
  image_id               = "ami-0bae57ee7c4478e01"
  instance_type          = "t2.micro"
  key_name               = "masterschool-cloud-course"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl start docker
    systemctl enable docker

    # ECR login on EC2
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin 156332912416.dkr.ecr.eu-central-1.amazonaws.com

    # Docker image pull
    docker pull 156332912416.dkr.ecr.eu-central-1.amazonaws.com/grocery-shop-repo:latest
    docker run -d --network host \
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
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "grocery-shop-instance"
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "grocery-shop-asg" {
  name = "grocery-shop-asg"

  launch_template {
    id      = aws_launch_template.grocery-shop-lt.id
    version = "$Latest"
  }
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public-a.id, aws_subnet.public-b.id]
  target_group_arns   = [aws_lb_target_group.grocery-shop-tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300
}

# Target Tracking CPU-Scaling
resource "aws_autoscaling_policy" "cpu-scaling" {
  name                   = "target-tracking-cpu"
  autoscaling_group_name = aws_autoscaling_group.grocery-shop-asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70
  }
}