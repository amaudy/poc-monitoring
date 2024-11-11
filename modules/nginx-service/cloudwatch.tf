resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/ecs/${var.project_name}/${var.environment}/nginx"
  retention_in_days = 30
  tags              = var.tags
}

data "aws_region" "current" {} 