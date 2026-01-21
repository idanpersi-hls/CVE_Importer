locals {
    source_url = "${dirname(find_in_parent_folders("root.hcl"))}/../modules//ecs-fargate"
    environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
    prefix = local.environment_vars.locals.prefix
    aws_region = local.environment_vars.locals.aws_region
    account_id = local.environment_vars.locals.account_id
    image_repo  = "${local.account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/idanpersi-skills/cve-etl"
    common_env_vars = [
    {
      name  = "NVD_API_URL"
      value = "https://services.nvd.nist.gov/rest/json/cves/2.0"
    },
    {
      name  = "DB_USER"
      value = "postgres"
    }
  ]
}

inputs = {
  aws_region = local.aws_region
  num_of_containers = 2
  cpu = 256
  memory = 512
  cluster_name = "${local.prefix}-cluster"
  task_family = "${local.prefix}-task-family"
  service_name = "${local.prefix}-service"
  container_name = "${local.prefix}-container"
  network_mode = "awsvpc"
  launch_type = "FARGATE"
  image_repo = local.image_repo
  desired_count = 1
}