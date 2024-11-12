# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/poc-datadog/lambda/${local.lambda_name}"
  retention_in_days = 1
  tags              = var.tags
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/poc-datadog/api-gateway/${local.lambda_name}"
  retention_in_days = 1
  tags              = var.tags
} 