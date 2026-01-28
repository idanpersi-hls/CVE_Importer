include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/ecs.hcl"
  expose = true
}

locals{
  prefix = include.envcommon.locals.prefix
  image = "${include.envcommon.locals.image_repo}:46"

  container_specs = [
    {
      name = "etl-worker"
      image = local.image
    },
    {
      name = "api-server"
      image = local.image
      essential = true
      command  = ["uvicorn", "src.api.api:app", "--host", "0.0.0.0", "--port", "8000"]
      portMappings = [{ containerPort = 8000, hostPort = 8000 }]
    } 
  ]

  service_specs = [
      {
      name = "${local.prefix}-etl-api-service"
      task_definition = "cve-task"
      launch_type = "FARGATE"
      desired_count = 1
      load_balancer = {
        target_group_key = "ecs_target"
        container_name   = "api-server"
        container_port   = 8000
      }
    }
  ]

}

inputs = {
  containers = [for spec in local.container_specs : merge(include.envcommon.inputs.container_defaults, spec)]

  tasks = {
    "cve-task" = merge(include.envcommon.inputs.task_defaults, 
    {
      family  = "${local.prefix}-task"
      containers = ["etl-worker", "api-server"] 
    })
  }

  services = [for spec in local.service_specs : merge(include.envcommon.inputs.service_defaults, spec)]
}