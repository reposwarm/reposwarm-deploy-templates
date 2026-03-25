# --------------------------------------------------
# ECS Cluster + Services
# --------------------------------------------------

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.name_prefix}-cluster"
  }
}

# --- Security Group for ECS Tasks ---

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${local.name_prefix}-ecs-tasks-"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Temporal gRPC from tasks"
    from_port   = 7233
    to_port     = 7233
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description     = "Temporal UI from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Inter-task communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ecs-tasks-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- CloudWatch Log Groups ---

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.name_prefix}/api"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.name_prefix}-api-logs"
  }
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${local.name_prefix}/worker"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.name_prefix}-worker-logs"
  }
}

resource "aws_cloudwatch_log_group" "ui" {
  name              = "/ecs/${local.name_prefix}/ui"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.name_prefix}-ui-logs"
  }
}

resource "aws_cloudwatch_log_group" "temporal" {
  name              = "/ecs/${local.name_prefix}/temporal"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.name_prefix}-temporal-logs"
  }
}

resource "aws_cloudwatch_log_group" "temporal_ui" {
  name              = "/ecs/${local.name_prefix}/temporal-ui"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.name_prefix}-temporal-ui-logs"
  }
}

# --- Service Discovery Services ---

resource "aws_service_discovery_service" "temporal" {
  name = "temporal"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "temporal_ui" {
  name = "temporal-ui"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "api" {
  name = "api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# ============================================================
# Temporal Server
# ============================================================

resource "aws_ecs_task_definition" "temporal" {
  family                   = "${local.name_prefix}-temporal"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.temporal_cpu
  memory                   = var.temporal_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "temporal"
    image     = "temporalio/auto-setup:latest"
    essential = true

    portMappings = [{
      containerPort = 7233
      protocol      = "tcp"
    }]

    environment = [
      { name = "DB", value = "postgres12" },
      { name = "DB_PORT", value = "5432" },
      { name = "POSTGRES_USER", value = "temporal" },
      { name = "POSTGRES_SEEDS", value = split(":", aws_db_instance.temporal.endpoint)[0] },
    ]

    secrets = [
      {
        name      = "POSTGRES_PWD"
        valueFrom = aws_secretsmanager_secret.rds_password.arn
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.temporal.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "temporal"
      }
    }
  }])

  tags = {
    Name = "${local.name_prefix}-temporal-task"
  }
}

resource "aws_ecs_service" "temporal" {
  name            = "${local.name_prefix}-temporal"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.temporal.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.temporal.arn
  }

  tags = {
    Name = "${local.name_prefix}-temporal-service"
  }
}

# ============================================================
# Temporal UI
# ============================================================

resource "aws_ecs_task_definition" "temporal_ui" {
  family                   = "${local.name_prefix}-temporal-ui"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.temporal_ui_cpu
  memory                   = var.temporal_ui_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "temporal-ui"
    image     = "temporalio/ui:latest"
    essential = true

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]

    environment = [
      { name = "TEMPORAL_ADDRESS", value = "temporal.reposwarm.local:7233" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.temporal_ui.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "temporal-ui"
      }
    }
  }])

  tags = {
    Name = "${local.name_prefix}-temporal-ui-task"
  }
}

resource "aws_ecs_service" "temporal_ui" {
  name            = "${local.name_prefix}-temporal-ui"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.temporal_ui.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.temporal_ui.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.temporal_ui.arn
    container_name   = "temporal-ui"
    container_port   = 8080
  }

  tags = {
    Name = "${local.name_prefix}-temporal-ui-service"
  }
}

# ============================================================
# API Service
# ============================================================

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.api_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = "api"
    image     = "ghcr.io/reposwarm/api:latest"
    essential = true

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    environment = [
      { name = "TEMPORAL_SERVER_URL", value = "temporal.reposwarm.local:7233" },
      { name = "TEMPORAL_HTTP_URL", value = "http://temporal-ui.reposwarm.local:8080" },
      { name = "TEMPORAL_NAMESPACE", value = "default" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "DYNAMODB_TABLE", value = aws_dynamodb_table.cache.name },
    ]

    secrets = [
      {
        name      = "API_BEARER_TOKEN"
        valueFrom = aws_secretsmanager_secret.api_bearer_token.arn
      }
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:3000/v1/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.api.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "api"
      }
    }
  }])

  tags = {
    Name = "${local.name_prefix}-api-task"
  }
}

resource "aws_ecs_service" "api" {
  name            = "${local.name_prefix}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.api.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 3000
  }

  tags = {
    Name = "${local.name_prefix}-api-service"
  }
}

# ============================================================
# Worker Service
# ============================================================

resource "aws_ecs_task_definition" "worker" {
  family                   = "${local.name_prefix}-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.worker_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = "worker"
    image     = "ghcr.io/reposwarm/worker:latest"
    essential = true

    environment = concat(
      [
        { name = "TEMPORAL_SERVER_URL", value = "temporal.reposwarm.local:7233" },
        { name = "TEMPORAL_NAMESPACE", value = "default" },
        { name = "TEMPORAL_TASK_QUEUE", value = "investigate-task-queue" },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "DYNAMODB_TABLE", value = aws_dynamodb_table.cache.name },
      ],
      var.use_bedrock ? [{ name = "CLAUDE_CODE_USE_BEDROCK", value = "1" }] : []
    )

    secrets = concat(
      var.github_token != "" ? [{
        name      = "GITHUB_TOKEN"
        valueFrom = aws_secretsmanager_secret.github_token[0].arn
      }] : [],
      var.gitlab_token != "" ? [{
        name      = "GITLAB_TOKEN"
        valueFrom = aws_secretsmanager_secret.gitlab_token[0].arn
      }] : [],
      var.anthropic_api_key != "" ? [{
        name      = "ANTHROPIC_API_KEY"
        valueFrom = aws_secretsmanager_secret.anthropic_api_key[0].arn
      }] : []
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.worker.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "worker"
      }
    }
  }])

  tags = {
    Name = "${local.name_prefix}-worker-task"
  }
}

resource "aws_ecs_service" "worker" {
  name            = "${local.name_prefix}-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = {
    Name = "${local.name_prefix}-worker-service"
  }
}

# ============================================================
# UI Service
# ============================================================

resource "aws_ecs_task_definition" "ui" {
  family                   = "${local.name_prefix}-ui"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ui_cpu
  memory                   = var.ui_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ui_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = "ui"
    image     = "ghcr.io/reposwarm/ui:latest"
    essential = true

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    environment = [
      { name = "TEMPORAL_SERVER_URL", value = "http://temporal-ui.reposwarm.local:8080" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "DYNAMODB_CACHE_TABLE", value = aws_dynamodb_table.cache.name },
      { name = "REPOSWARM_API_URL", value = "http://api.reposwarm.local:3000" },
    ]

    secrets = [
      {
        name      = "API_BEARER_TOKEN"
        valueFrom = aws_secretsmanager_secret.api_bearer_token.arn
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ui.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ui"
      }
    }
  }])

  tags = {
    Name = "${local.name_prefix}-ui-task"
  }
}

resource "aws_ecs_service" "ui" {
  name            = "${local.name_prefix}-ui"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ui.arn
  desired_count   = var.ui_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ui.arn
    container_name   = "ui"
    container_port   = 3000
  }

  tags = {
    Name = "${local.name_prefix}-ui-service"
  }
}
