output "alb-dns-name" {
  description = "ALB - public URL"
  value       = aws_lb.alb.dns_name
}

output "database_endpoint" {
  description = "RDS-DB DNS Endpoint"
  value       = aws_db_instance.aws_shop_db.endpoint
}

output "state_bucket_name" {
  description = "Bucket-Name"
  value       = aws_s3_bucket.avatars.id
}