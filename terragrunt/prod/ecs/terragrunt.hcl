include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/ecs.hcl"
  expose = true
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_output = "mock-vpc-output"
    private_subnets = ["mock-subnet-1","mock-subnet-2"]
    vpc_id = "mock-id"
  }
}

dependency "rds" {
    config_path = "../rds"
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

terraform {
    source = "${include.envcommon.locals.source_url}"
}

locals{
  prefix = include.envcommon.locals.prefix
  image = "${include.envcommon.locals.image_repo}:45"
}

inputs = {
  connect_to_rds_sg_id = dependency.rds.outputs.connect_to_rds_sg_id
  port = dependency.rds.outputs.db_instance_port
  vpc_id = dependency.vpc.outputs.vpc_id
  private_subnets = dependency.vpc.outputs.private_subnets
  db_instance_arn = dependency.rds.outputs.db_instance_arn
  db_master_user_secret_arn = dependency.rds.outputs.db_master_user_secret_arn

  containers = [
    {
      name = "etl-worker"
      image = local.image
      cpu = 256
      memory = 512
      essential = false
      environment = concat(include.envcommon.locals.common_env_vars, [
        { name = "DB_HOST", value = dependency.rds.outputs.db_instance_address },
        { name = "DB_PORT", value = tostring(dependency.rds.outputs.db_instance_port) },
        { name = "DB_NAME", value = dependency.rds.outputs.db_instance_name },
        { name = "START_DATE", value = "2025-10-01T00:00:00+00:00" } ])
      secrets = [{ name = "DB_PASSWORD", valueFrom = "${dependency.rds.outputs.db_master_user_secret_arn}:password::" }]
    },
    {
      name = "api-server"
      image = local.image
      cpu  = 256
      memory = 512
      essential = true
      command  = ["python", "-m", "src.api.api"]
      environment = concat(include.envcommon.locals.common_env_vars, [
        { name = "DB_HOST", value = dependency.rds.outputs.db_instance_address },
        { name = "DB_PORT", value = tostring(dependency.rds.outputs.db_instance_port) },
        { name = "DB_NAME", value = dependency.rds.outputs.db_instance_name },
        { name = "START_DATE", value = "2025-10-01T00:00:00+00:00" }])
      portMappings = [{ containerPort = 8000, hostPort = 8000 }]
      secrets = [{ name = "DB_PASSWORD", valueFrom = "${dependency.rds.outputs.db_master_user_secret_arn}:password::" }]
    }
  ]

  tasks = {
    "cve-task" = {
      family  = "${local.prefix}-task"
      containers = ["etl-worker", "api-server"] 
      cpu  = 512
      memory = 1024
      requires_compatibilities = ["FARGATE"]
      network_mode  = "awsvpc"
    }
  }

  services = [
    {
      name = "${local.prefix}-etl-api-service"
      task_definition = "cve-task"
      launch_type = "FARGATE"
      desired_count = 1
    }
  ]
}