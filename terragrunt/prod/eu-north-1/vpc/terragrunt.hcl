include "root" {
    path = find_in_parent_folders("root.hcl")
    expose = true
}

terraform {
    source = "tfr:///terraform-aws-modules/vpc/aws?version=6.6.0"
}

locals {
    prefix = include.root.locals.prefix
}

inputs ={
    name = "${local.prefix}tg-vpc"
    cidr = "10.0.0.0/16"
    azs = ["eu-north-1a", "eu-north-1b", "eu-north-1c"] #TODO DRY
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
    database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
    enable_nat_gateway = true
    enable_vpn_gateway = false
    manage_default_route_table = false
}
