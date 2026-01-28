output "target_groups" {
  value = module.alb.target_groups
}
output "access_from_alb_id" {
  value = aws_security_group.access_from_alb.id
}
output "alb_dns_name" {
  value = module.alb.dns_name
}