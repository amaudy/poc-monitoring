# Add policy to allow ECS task to read Datadog API key
resource "aws_iam_role_policy" "task_execution_datadog" {
  name = "${local.name_prefix}-datadog-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          data.aws_secretsmanager_secret.datadog_api_key.arn
        ]
      }
    ]
  })
} 