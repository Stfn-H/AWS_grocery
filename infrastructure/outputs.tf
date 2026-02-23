output "webserver_ip" {
  description = "public IP - EC2"
  value       = aws_instance.grocery-shop-webserver.public_ip
}

output "database_endpoint" {
  description = "RDS-DB DNS Endpoint"
  value       = aws_db_instance.aws_shop_db.endpoint
}