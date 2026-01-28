locals {
  source_url = "${dirname(find_in_parent_folders("root.hcl"))}/../modules//ecs-fargate"
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  prefix = local.environment_vars.locals.prefix
  aws_region = local.environment_vars.locals.aws_region
  account_id = local.environment_vars.locals.account_id
  image_repo  = "${local.account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/idanpersi-skills/cve-etl"

  base_dir = dirname(find_in_parent_folders("root.hcl"))
  env_name = basename(dirname(get_terragrunt_dir()))

  common_env_vars = [
      { name  = "NVD_API_URL", value = "https://services.nvd.nist.gov/rest/json/cves/2.0" },
      { name  = "DB_USER", value = "postgres" },
      { name = "DB_SSL_MODE", value = "require" },
      { name = "START_DATE", value = "2025-10-01T00:00:00+00:00" },
  ]
}

terraform {
  source = local.source_url
}

dependency "rds" {
    config_path = "${local.base_dir}/${local.env_name}/rds"
    mock_outputs = {
        rds_output = "mock-rds-output"
        connect_to_rds_sg_id = "mock-sg-id"
        db_instance_port = "1234"
        db_instance_address = "mock address"
        db_instance_name = "mock-name"
        db_master_user_secret_arn = "arn:aws:secretsmanager:eu-north-1:123456789:secret:mock-secret"
        db_instance_arn = "arn:aws:mock"
    }
}

dependency "alb" {
  config_path = "${local.base_dir}/${local.env_name}/alb"
  mock_outputs = {
    target_groups = {
      "ecs_target" = {
        arn = "arn:aws:elasticloadbalancing:mock:123456789012:targetgroup/mock/123456"
      }
    }
    access_from_alb_id = "sg-mock-id"
  }
}

dependency "vpc" {
  config_path = "${local.base_dir}/${local.env_name}/vpc"
  mock_outputs = {
    vpc_output = "mock-vpc-output"
    private_subnets = ["mock-subnet-1","mock-subnet-2"]
    vpc_id = "mock-id"
  }
}

inputs = {
  container_defaults = {
    name = "default container"
    cpu = 512
    memory = 1024
    essential = false
    environment= concat(local.common_env_vars,
    [
      { name = "DB_HOST", value = dependency.rds.outputs.db_instance_address },
      { name = "DB_PORT", value = tostring(dependency.rds.outputs.db_instance_port) },
      { name = "DB_NAME", value = dependency.rds.outputs.db_instance_name }
    ])
    secrets = [{ name = "DB_PASSWORD", valueFrom = "${dependency.rds.outputs.db_master_user_secret_arn}:password::" }]
  }
  
  task_defaults = {
    cpu  = 1024
    memory = 2048
    requires_compatibilities = ["FARGATE"]
    network_mode  = "awsvpc"
  }

  service_defaults = {
    name = "default service"
    security_groups = [dependency.rds.outputs.connect_to_rds_sg_id, dependency.alb.outputs.access_from_alb_id]
    private_subnets = dependency.vpc.outputs.private_subnets
  }

  port = dependency.rds.outputs.db_instance_port
  vpc_id = dependency.vpc.outputs.vpc_id
  db_instance_arn = dependency.rds.outputs.db_instance_arn
  db_master_user_secret_arn = dependency.rds.outputs.db_master_user_secret_arn
  alb_target_groups = dependency.alb.outputs.target_groups

  logs_aws_region = local.aws_region
  image_repo = local.image_repo
  cluster_name = "${local.prefix}-cluster"
  role_and_policy_prefix = "${local.prefix}-task"
}