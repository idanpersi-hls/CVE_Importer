module "alb" {
    source  = "terraform-aws-modules/alb/aws"
    version = "10.5.0"
    name = 
    load_balancer_type = "application"
    security_group_description =
    security_group_ingress_rules =
    security_group_egress_rules = 
    security_group_name =
    create_security_group = true
    default_port = 8000
    enable_deletion_protection = false # should be true - easyer to test this way
    health_check_logs =
    internal =
    listeners =

}