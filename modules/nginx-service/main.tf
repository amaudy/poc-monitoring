locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Task Definition
resource "aws_ecs_task_definition" "nginx" {
  family                   = "${local.name_prefix}-nginx"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = var.cpu
  memory                  = var.memory
  execution_role_arn      = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "datadog-agent"
      image     = "public.ecr.aws/datadog/agent:latest"
      essential = true

      environment = [
        {
          name  = "DD_SITE"
          value = var.datadog_region
        },
        {
          name  = "DD_APM_ENABLED"
          value = "true"
        },
        {
          name  = "DD_APM_NON_LOCAL_TRAFFIC"
          value = "true"
        },
        {
          name  = "DD_LOGS_ENABLED"
          value = "true"
        },
        {
          name  = "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL"
          value = "true"
        },
        {
          name  = "DD_CONTAINER_EXCLUDE"
          value = "name:datadog-agent"
        },
        {
          name  = "ECS_FARGATE"
          value = "true"
        },
        {
          name  = "DD_PROCESS_AGENT_ENABLED"
          value = "true"
        },
        {
          name  = "DD_SYSTEM_PROBE_ENABLED"
          value = "true"
        },
        {
          name  = "DD_PROCESS_CONFIG_LOG_FILE"
          value = "/dev/stdout"
        },
        {
          name  = "DD_LOGS_CONFIG_PROCESSING_RULES"
          value = "[{\"type\":\"multi_line\", \"name\":\"log_start_with_date\", \"pattern\":\"\\\\d{4}-(0?[1-9]|1[012])-(0?[1-9]|[12][0-9]|3[01])\"}]"
        },
        {
          name  = "DD_CONTAINER_EXCLUDE_LOGS"
          value = "name:datadog-agent"
        },
        {
          name  = "DD_TAGS"
          value = "env:${var.environment},service:nginx,project:${var.project_name},version:${var.service_version}"
        },
        {
          name  = "DD_DOCKER_LABELS_AS_TAGS"
          value = "{\"com.docker.compose.service\":\"service_name\"}"
        },
        {
          name  = "DD_CONTAINER_LABELS_AS_TAGS"
          value = "{\"service\":\"service_name\"}"
        }
      ]

      secrets = [
        {
          name      = "DD_API_KEY"
          valueFrom = data.aws_secretsmanager_secret.datadog_api_key.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.nginx.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "datadog-agent"
        }
      }
    },
    {
      name      = "nginx"
      image     = "nginx:latest"
      essential = true

      dockerLabels = {
        "com.datadoghq.ad.logs" = "[{\"source\": \"nginx\", \"service\": \"nginx\", \"version\": \"${var.service_version}\"}]"
        "service"               = "nginx"
        "version"              = var.service_version
      }

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.nginx.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "nginx"
        }
      }

      dependsOn = [
        {
          containerName = "datadog-agent"
          condition     = "START"
        }
      ]
    }
  ])

  tags = merge(var.tags, {
    Version = var.service_version
  })
}

# ECS Service
resource "aws_ecs_service" "nginx" {
  name            = "${local.name_prefix}-nginx"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.nginx_task.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx.arn
    container_name   = "nginx"
    container_port   = var.container_port
  }

  tags = merge(var.tags, {
    Version = var.service_version
  })

  depends_on = [aws_lb_listener.http]
}

# Application Load Balancer
resource "aws_lb" "nginx" {
  name               = "${local.name_prefix}-nginx"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.public_subnets

  tags = merge(var.tags, {
    Version = var.service_version
  })
}

resource "aws_lb_target_group" "nginx" {
  name        = "${local.name_prefix}-nginx"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    path                = "/"
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
} 