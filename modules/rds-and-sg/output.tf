output "connect_to_rds_sg_id" {
  value = aws_security_group.connect_to_rds.id
}
output "db_instance_port" {
  value = module.db.db_instance_port
}
output "db_instance_address" {
  value = module.db.db_instance_address
}
output "db_instance_name" {
  value = module.db.db_instance_name
}
output "db_master_user_secret_arn" {
  value = module.db.db_instance_master_user_secret_arn
}
output "db_instance_arn" {
  value = module.db.db_instance_arn
}