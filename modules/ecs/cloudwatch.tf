resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}/${var.cluster_name}"
  retention_in_days = 30
  tags              = var.tags
} 