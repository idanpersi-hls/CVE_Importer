variable "connect_to_rds_sg_id" {
  type = string
  description = "the db's security group needed to connect"
}
variable "port" {
  type = number
  description = "the port of the db to connect to"
}
variable "vpc_id" {
  type = string
}
variable "container_environments" {
  description = "A list of environment variables to pass to the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
variable "private_subnets" {
  type = list(string)
}
variable "cluster_name" {
  type = string
}
variable "task_family" {
  type = string
}
variable "network_mode" {
  type = string
}
variable "secrets" {
  type = list(object({
    name  = string
    valueFrom = string
  }))
  default = []
  }
variable "db_instance_arn" {
  type = string
}
variable "db_master_user_secret_arn" {
  type = string
}
variable "cpu" {
  type = number
}
variable "memory" {
  type = number
}
variable "launch_type" {
  type = string
}
variable "image_repo" {
  type = string
}
variable "image_tag" {
  type = string
}
variable "container_name" {
  type = string
}
variable "service_name" {
  type = string
}
variable "desired_count" {
  type = number
}
variable "num_of_containers" {
  type = number
}
variable "aws_region" {
  type = string
}