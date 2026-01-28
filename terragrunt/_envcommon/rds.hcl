locals {
  source_url = "${dirname(find_in_parent_folders("root.hcl"))}/../modules//rds-and-sg"
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  prefix = local.environment_vars.locals.prefix
  aws_region = local.environment_vars.locals.aws_region
  
  base_dir = dirname(find_in_parent_folders("root.hcl"))
  env_name = basename(dirname(get_terragrunt_dir()))
}

terraform {
  source = local.source_url
}

dependency "vpc" {
  config_path = "${local.base_dir}/${local.env_name}/vpc"

  mock_outputs = {
    vpc_output = "mock-vpc-output"
    database_subnet_group_name = "mock-subnet-name"
    vpc_id = "mock-id"
    database_subnets_cidr_blocks = ["10.0.0.0/24"]
  }
}

inputs = {
  db_subnet_group_name = dependency.vpc.outputs.database_subnet_group_name
  vpc_id = dependency.vpc.outputs.vpc_id
  allowd_cidr = dependency.vpc.outputs.database_subnets_cidr_blocks

  identifier = "${local.prefix}-postgress"
  rds_security_group_name = "${local.prefix}-rds-sg"
  connect_to_rds_sg_name = "${local.prefix}-connect-to-rds-sg"
  engine = "postgres"
  engine_version = "17"
  family = "postgres17"
  major_engine_version = "17"
  username = "postgres"
  port = 5432
  db_name = "cves"
  allocated_storage = 20
  max_allocated_storage = 100
  manage_master_user_password = true
  publicly_accessible = false
  create_db_instance = true
  create_db_subnet_group = false
  storage_encrypted = true
}