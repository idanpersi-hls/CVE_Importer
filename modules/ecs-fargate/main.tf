locals {
  common_log_config = {
    logDriver = "awslogs"
    options = {
      "awslogs-group" = aws_cloudwatch_log_group.this.name
      "awslogs-region"  = var.aws_region
      "awslogs-stream-prefix" = "ecs"
    }
  }
}

resource "aws_ecs_cluster" "ecs_cluser" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "task_def" {
    family = var.task_family
    requires_compatibilities = [ var.launch_type ]
    network_mode = var.network_mode
    cpu = var.cpu * var.num_of_containers
    memory = var.memory * var.num_of_containers
    execution_role_arn = aws_iam_role.execution_role.arn
    
    container_definitions = jsonencode([{ 
    name = "${var.container_name}-etl"
    image  = "${var.image_repo}:${var.image_tag}"
    cpu = var.cpu
    memory = var.memory
    essential = false
    environment = var.container_environments
    secrets = var.secrets
    logConfiguration = local.common_log_config
  },
  {
    name = "${var.container_name}-api"
    image  = "${var.image_repo}:${var.image_tag}"
    cpu = var.cpu
    memory = var.memory
    essential = true
    command = ["python", "-m", "src.api.api"]
    portMappings = [
      {
      containerPort = 8000
      hostPort = 8000
      }]
    environment = var.container_environments
    secrets = var.secrets
    logConfiguration = local.common_log_config
  }])

}

resource "aws_ecs_service" "ecs_service" {
  name = var.service_name
  cluster = aws_ecs_cluster.ecs_cluser.id
  task_definition = aws_ecs_task_definition.task_def.arn
  launch_type = var.launch_type
  desired_count = var.desired_count

  network_configuration {
    assign_public_ip = false
    security_groups = [ var.connect_to_rds_sg_id ]

    subnets = var.private_subnets
  }
  
}


resource "aws_iam_role" "execution_role" {
  name = "${var.task_family}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

data "aws_iam_policy_document" "execution_policy_doc" {
  
  statement {
    sid    = "AllowECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowECRPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }

  statement {
    sid = "AllowSecretsFetch"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = ["${var.db_master_user_secret_arn}"]
  }
}


resource "aws_iam_policy" "execution_policy" {
  name  = "${var.task_family}-execution-policy"
  policy = data.aws_iam_policy_document.execution_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "execution_attach" {
  role = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.execution_policy.arn
}
resource "aws_cloudwatch_log_group" "this" {
  name  = "/ecs/${var.task_family}"
  retention_in_days = 30
}