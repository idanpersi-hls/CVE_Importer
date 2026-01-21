variable "connect_to_rds_sg_id" {
  type = string
  description = "the db's security group needed to connect"
}
variable "private_subnets" {
  type = list(string)
}
variable "cluster_name" {
  type = string
}

variable "db_master_user_secret_arn" {
  type = string
}

variable "logs_aws_region" {
  type = string
}

variable "containers" {
  description = "List of container definitions"
  type = list(object({
    name              = string
    image             = string
    cpu               = number
    memory            = number
    essential         = bool
    command           = optional(list(string))
    environment       = optional(list(object({
      name  = string
      value = string
    })), [])
    secrets           = optional(list(object({
      name      = string
      valueFrom = string
    })), [])
    portMappings      = optional(list(object({
      containerPort = number
      hostPort      = number
      protocol      = optional(string, "tcp")
    })), [])
  }))
}

variable "services" {
  description = "List of ECS services to create"
  type = list(object({
    name           = string
    task_definition = string  # Which task to use
    launch_type = string
    desired_count  = number
    deployment_configuration = optional(object({
      maximum_percent         = number
      minimum_healthy_percent = number
    }), {
      maximum_percent         = 200
      minimum_healthy_percent = 100
    })
  }))
}

variable "tasks" {
  description = "Task definitions with their configurations"
  type = map(object({
    family                   = string
    containers               = list(string)  # container names
    cpu                      = number
    memory                   = number
    requires_compatibilities = list(string)
    network_mode             = string
  }))
}

variable "role_and_policy_prefix" {
  type = string
}