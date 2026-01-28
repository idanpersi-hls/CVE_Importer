module "db" {
    source  = "terraform-aws-modules/rds/aws"
    version = "~> 7.1"
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
    vpc_security_group_ids = [aws_security_group.rds.id]
}

resource "aws_security_group" "rds" {
  name =  var.rds_security_group_name
  vpc_id      = var.vpc_id
  description = "SG for the rds"
  tags = {
    Name = var.rds_security_group_name
  }
}

resource "aws_security_group" "connect_to_rds" {
  name = var.connect_to_rds_sg_name
  vpc_id = var.vpc_id
  description = "SG for resources to cennect to rds"
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = var.connect_to_rds_sg_name
  }
}

resource "aws_security_group_rule" "allow_connection" {
  type = "ingress"
  security_group_id = aws_security_group.rds.id
  from_port = var.port
  to_port = var.port
  protocol = "tcp"
  source_security_group_id = aws_security_group.connect_to_rds.id
}
