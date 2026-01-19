    variable "engine" {
        type    = string
    }

    variable "engine_version" {
        type    = string
    }

    variable "family" {
        type    = string
    }

    variable "major_engine_version" {
        type    = string
    }

    variable "allocated_storage" {
        type    = number
    }

    variable "max_allocated_storage" {
        type    = number
    }

    variable "storage_encrypted" {
        type    = bool
    }

    variable "username" {
        type    = string
    }

    variable "manage_master_user_password" {
        type    = bool
    }

    variable "port" {
        type    = number
    }

    variable "multi_az" {
        type    = bool
    }

    variable "publicly_accessible" {
        type    = bool
    }

    variable "backup_retention_period" {
        type    = number
    }

    variable "skip_final_snapshot" {
        type    = bool
    }

    variable "deletion_protection" {
        type    = bool
    }

    variable "identifier" {
        type    = string
    }

    variable "instance_class" {
        type    = string
    }

    variable "db_name" {
        type    = string
    }

    variable "db_subnet_group_name" {
        type    = string
    }

    variable "create_db_instance" {
        type    = bool
    }

    variable "create_db_subnet_group" {
        type    = bool
    }

    variable "allowed_cidrs" {
        type = list(string)
        default = []
    }
    
    variable "vpc_id" {
      type = string
    }

    variable "sg_name" {
      type = string
    }