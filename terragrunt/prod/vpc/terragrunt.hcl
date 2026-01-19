include "root" {
    path = find_in_parent_folders("root.hcl")
    expose = true
}

include "envcommon" {
    path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/vpc.hcl"
    expose = true
}

terraform {
    source = "${include.envcommon.locals.source_url}//?ref=v6.6.0"
}

locals {
    prefix = include.root.locals.prefix
    aws_region = include.root.locals.aws_region
}

inputs = {
    name = "${local.prefix}-terra-vpc"
    azs = [for suffix in ["a", "b", "c"] : "${local.aws_region}${suffix}"]
}