locals {
  prefix = "idanpersi-skills-"
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  account_id   = local.account_vars.locals.account_id
  account_name = local.account_vars.locals.account_name
  aws_region   = local.region_vars.locals.aws_region
}

remote_state {
  backend = "s3"
  
  config = {
    bucket         = "${local.prefix}terraform-state-${local.account_name}-${local.account_id}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "${local.prefix}terraform-locks-${local.account_name}"
    
    s3_bucket_tags = {
      Name        = "Terraform State"
    }
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  
  contents = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  
  default_tags {
    tags = {
      ManagedBy   = "Terragrunt"
      Environment = "${local.account_name}"
      Region      = "${local.aws_region}"
    }
  }
}
EOF
}

