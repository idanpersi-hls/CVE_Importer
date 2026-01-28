include "root" {
	path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
	path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/alb.hcl"
	expose = true
}

locals {
	prefix = include.envcommon.locals.prefix
	listener_port = 80
}

inputs = {
  listener_port = local.listener_port
	target_groups = {
		"ecs_target" = merge(include.envcommon.locals.target_group_defaults,
			{
			name = "${local.prefix}-tg-ecs"
      		vpc_id = include.envcommon.inputs.vpc_id
			health_check = merge(include.envcommon.locals.health_check_defaults,
			{
				path = "/health"
				timeout  = 10
				interval = 20
			})
		})
	}
	listeners = {
		"http" = {
			port = local.listener_port
			forward = {
				target_group_key = "ecs_target" 
			}
   		}
  	}
}