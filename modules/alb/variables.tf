variable "public_subnets" {
  type = list(string)
}
variable "vpc_id" {
  type = string
}
variable "load_balancer_type" {
  type = string
}
variable "load_balancer_name" {
  type = string
}
variable "app_port" {
  type = number
}
variable "internal" {
  type = bool
}
variable "enable_deletion_protection" {
  type = bool
}
variable "default_protocol" {
  type = string
}
variable "target_groups" {
  description = "A map of target groups and their parameters"
  type = map(object({
    name              = string
    target_type       = optional(string, "ip")
    vpc_id            = string
    create_attachment = optional(bool, false)
    backend_protocol  = optional(string, "HTTP")
    backend_port      = optional(number)

    health_check = object({
      enabled  = optional(bool, true)
      path     = string
      timeout  = number
      interval = number
      matcher  = string
      port     = optional(string) 
    })
  }))
}

variable "listeners" {
  description = "A map of listeners and their parameters"
  type = map(object({
    protocol = optional(string)
    ssl_policy = optional(string)
    port = optional(number)
    certificate_arn  = optional(string)
    forward = object({
      target_group_key = optional(string)
      target_group_arn = optional(string)
    })
  }))
}
variable "alb_security_group_ingress_rules" {
  type = map(object({
    from_port = number
    to_port = number
    ip_protocol = string
    cidr_ipv4 = optional(string)
    cidr_ipv6 = optional(string)
    prefix_list_id = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {}
}
variable "target_security_group_name" {
  type = string
}
variable "allow_cloudfront" {
  description = "If true, restricts ALB ingress to CloudFront IPs only"
  type        = bool
  default     = false
}
variable "listener_port" {
  type = number
}