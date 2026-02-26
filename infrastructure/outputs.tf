output "webserver_ip" {
  description = "public IP - EC2"
  value       = aws_instance.grocery-shop-webserver.public_ip
}

output "webserver_dns" {
  description = "public DNS - EC2"
  value = aws_instance.grocery-shop-webserver.public_dns
}

output "database_endpoint" {
  description = "RDS-DB DNS Endpoint"
  value       = aws_db_instance.aws_shop_db.endpoint
}

output "state_bucket_name" {
  description = "Bucket-Name"
  value       = aws_s3_bucket.avatars.id
}