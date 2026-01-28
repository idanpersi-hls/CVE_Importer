locals {
  base_dir = dirname(find_in_parent_folders("root.hcl"))
  env_name = basename(dirname(get_terragrunt_dir()))
  source_url = "${dirname(find_in_parent_folders("root.hcl"))}/../modules//cloudfront"
}

terraform {
	source = local.source_url
}


dependency "alb" {
  config_path = "${local.base_dir}/${local.env_name}/alb"
  
  mock_outputs = {
    alb_dns_name  = "mock-alb-dns.us-east-1.elb.amazonaws.com"
    load_balancer_name = "mock-alb"
  }
}

inputs = {
  alb_dns_name = dependency.alb.outputs.alb_dns_name
  price_class = "PriceClass_100"
  origin_protocol_policy = "http-only"
  allowed_methods = ["GET", "HEAD"]
  origin_ssl_protocols = ["TLSv1.2"]
}