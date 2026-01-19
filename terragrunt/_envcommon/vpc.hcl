locals {
    source_url = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git"
    base_cidr = "10.200.0.0/16"
    newbits = 8
}

inputs = {
    cidr = local.base_cidr
    private_subnets = [for i in [1, 2, 3] : cidrsubnet(local.base_cidr, local.newbits, i)]
    public_subnets  = [for i in [101, 102, 103] : cidrsubnet(local.base_cidr, local.newbits, i)]
    database_subnets = [for i in [201, 202, 203] : cidrsubnet(local.base_cidr, local.newbits, i)]
    enable_nat_gateway = true
    enable_vpn_gateway = false
    manage_default_route_table = false
    create_database_subnet_route_table = true
}