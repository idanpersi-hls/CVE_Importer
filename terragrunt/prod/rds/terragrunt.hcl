include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/rds.hcl"
  expose = true
}

inputs = {
  instance_class = "db.t4g.micro"
  multi_az = true
  backup_retention_period = 7

  skip_final_snapshot = false
  deletion_protection = false # for testing
}