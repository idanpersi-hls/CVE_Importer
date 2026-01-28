data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

locals {
  cloudfront_rule = var.allow_cloudfront ? {
    "cloudfront_ingress" = {
      from_port      = var.listener_port
      to_port        = var.listener_port
      ip_protocol    = "tcp"
      description    = "Allow traffic only from CloudFront"
      prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
    }
  } : {}
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.5"
  name = var.load_balancer_name
  load_balancer_type = var.load_balancer_type
  vpc_id = var.vpc_id
  subnets = var.public_subnets
  internal = var.internal
  enable_deletion_protection = var.enable_deletion_protection
  
  create_security_group = true
  security_group_description = "alb for cve-etl skills project"

  security_group_ingress_rules = merge(
    var.alb_security_group_ingress_rules, 
    local.cloudfront_rule
  )

  security_group_egress_rules = {
    "egress_to_created_sg" = {
      from_port = "${var.app_port}"
      to_port = "${var.app_port}"
      ip_protocol = "tcp"
      referenced_security_group_id = aws_security_group.access_from_alb.id
    }
  }
  default_protocol = var.default_protocol
  default_port = var.app_port

  target_groups = var.target_groups

  listeners = var.listeners
  
  health_check_logs = {
    bucket  = "idanpersi-skills-terra-alb-logs" 
    prefix  = "health-checks"
    enabled = true
  }
}
resource "aws_security_group" "access_from_alb" {
  name = var.target_security_group_name
  vpc_id = var.vpc_id
  ingress {
  from_port = "${var.app_port}"
  to_port = "${var.app_port}"
  protocol = "tcp"
  security_groups = [module.alb.security_group_id]
  }
}
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "idanpersi-skills-terra-alb-logs"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/health-checks/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}