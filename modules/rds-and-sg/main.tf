module "db" {
    source  = "terraform-aws-modules/rds/aws"
    version = "7.1.0"
    engine               = var.engine
    engine_version       = var.engine_version
    family               = var.family
    major_engine_version = var.major_engine_version

    allocated_storage     = var.allocated_storage
    max_allocated_storage = var.max_allocated_storage
    storage_encrypted     = var.storage_encrypted

    username = var.username
    manage_master_user_password = var.manage_master_user_password 
    port = var.port

    multi_az            = var.multi_az
    publicly_accessible = var.publicly_accessible

    backup_retention_period = var.backup_retention_period
    skip_final_snapshot     = var.skip_final_snapshot
    deletion_protection     = var.deletion_protection
    identifier     = var.identifier
    instance_class = var.instance_class
    db_name = var.db_name

    db_subnet_group_name = var.db_subnet_group_name

    create_db_instance = var.create_db_instance
    create_db_subnet_group = var.create_db_subnet_group
    vpc_security_group_ids = [aws_security_group.this.id]
}

resource "aws_security_group" "this" {
  name =  var.sg_name
  vpc_id      = var.vpc_id
  description = "SG created to allow ingress to rds only from vpc"
  tags = {
    Name = var.sg_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = toset(var.allowed_cidrs)
  security_group_id = aws_security_group.this.id
  
  cidr_ipv4         = each.value
  from_port         = var.port
  ip_protocol       = "tcp"
  to_port           = var.port
}
