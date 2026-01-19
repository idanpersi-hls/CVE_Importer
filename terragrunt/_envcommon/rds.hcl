

locals {
    source_url = "${dirname(find_in_parent_folders("root.hcl"))}/../modules//rds-and-sg"
}

inputs = {
    engine = "postgres"
    engine_version = "17"
    family = "postgres17"
    major_engine_version = "17"
    username = "postgres"
    port = 5432
    db_name = "cves"
    allocated_storage = 20
    max_allocated_storage = 100
    manage_master_user_password = true
    publicly_accessible = false
    create_db_instance = true
    create_db_subnet_group = false
    storage_encrypted = true
}