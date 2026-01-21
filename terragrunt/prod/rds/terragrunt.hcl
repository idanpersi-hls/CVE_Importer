include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/rds.hcl"
  expose = true
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_output = "mock-vpc-output"
    database_subnet_group_name = "mock-subnet-name"
    vpc_id = "mock-id"
    database_subnets_cidr_blocks = ["10.0.0.0/24"]
  }
}

terraform {
  source = "${include.envcommon.locals.source_url}"
}

inputs = {
  instance_class = "db.t4g.micro"
  multi_az = true
  backup_retention_period = 7

  skip_final_snapshot = false
  deletion_protection = false # for testing
  
  db_subnet_group_name = dependency.vpc.outputs.database_subnet_group_name
  vpc_id = dependency.vpc.outputs.vpc_id
  allowd_cidr = dependency.vpc.outputs.database_subnets_cidr_blocks
}