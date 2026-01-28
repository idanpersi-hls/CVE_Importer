locals{
  source_url = "${dirname(find_in_parent_folders("root.hcl"))}/../modules//alb"
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  prefix = local.environment_vars.locals.prefix
  aws_region = local.environment_vars.locals.aws_region

  base_dir = dirname(find_in_parent_folders("root.hcl"))
  env_name = basename(dirname(get_terragrunt_dir()))

  target_group_defaults = {
    name = "default_name"
    target_type = "ip"
    create_attachment = false
  }

  health_check_defaults = {
    enabled  = true
    path = "/"
    timeout  = 5
    interval = 10
    matcher = "200"
  }
}

dependency "vpc" {
	config_path = "${local.base_dir}/${local.env_name}/vpc"
	mock_outputs = {
		vpc_output = "mock-vpc-output"
		public_subnets = ["mock-subnet-1","mock-subnet-2"]
		vpc_id = "mock-id"
	}
}

terraform {
	source = local.source_url
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
	public_subnets = dependency.vpc.outputs.public_subnets

  load_balancer_name = "${local.prefix}-alb"
  load_balancer_type = "application"
  internal = false
  enable_deletion_protection = false # should be true - easyer to test this way
  default_protocol = "HTTP"
  app_port = 8000

  target_security_group_name = "${local.prefix}-access-from-alb"

  allow_cloudfront = true
  alb_security_group_ingress_rules = {}
}