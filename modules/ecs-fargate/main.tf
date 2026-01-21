resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "tasks" {
  for_each = var.tasks

  family                   = each.value.family
  requires_compatibilities = each.value.requires_compatibilities
  network_mode             = each.value.network_mode
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.execution_role.arn

  container_definitions = jsonencode([
    for container_name in each.value.containers :
    local.container_map[container_name]
  ])
}

locals {
  common_log_config = {
    logDriver = "awslogs"
    options = {
      "awslogs-group" = aws_cloudwatch_log_group.this.name
      "awslogs-region"  = var.logs_aws_region
      "awslogs-stream-prefix" = "ecs"
    }
  }
  container_map = {
  for container in var.containers :
  container.name => {
    name              = container.name
    image             = container.image
    cpu               = container.cpu
    memory            = container.memory
    essential         = container.essential
    command           = container.command
    environment       = container.environment
    secrets           = container.secrets
    portMappings      = container.portMappings
    logConfiguration  = local.common_log_config
    }
  }
}
resource "aws_ecs_service" "services" {
  for_each = {
    for service in var.services :
    service.name => service
  }

  name            = each.value.name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.tasks[each.value.task_definition].arn
  launch_type     = each.value.launch_type
  desired_count   = each.value.desired_count
  deployment_maximum_percent = each.value.deployment_configuration.maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_configuration.minimum_healthy_percent

  network_configuration {
    assign_public_ip = false
    security_groups  = [var.connect_to_rds_sg_id]
    subnets          = var.private_subnets
  }
}

resource "aws_iam_role" "execution_role" {
  name = "${var.role_and_policy_prefix}-execution-role"
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
  name  = "${var.role_and_policy_prefix}-execution-policy"
  policy = data.aws_iam_policy_document.execution_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "execution_attach" {
  role = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.execution_policy.arn
}
resource "aws_cloudwatch_log_group" "this" {
  name  = "/ecs/${var.role_and_policy_prefix}"
  retention_in_days = 30
}