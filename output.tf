output "MsSQL-IP" {
  value = aws_db_instance.wp-db.address
}

output "db-user" {
  value = var.aws_wp_db_user
}