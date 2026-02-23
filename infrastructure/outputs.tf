output "webserver_ip" {
  description = "public IP - EC2"
  value       = aws_instance.grocery-shop-webserver.public_ip
}

output "database_endpoint" {
  description = "RDS-DB DNS Endpoint"
  value       = aws_db_instance.aws_shop_db.endpoint
}

output "ecr_repository_url" {
  description = "Repo URL"
  value       = aws_ecr_repository.app_repo.repository_url
}