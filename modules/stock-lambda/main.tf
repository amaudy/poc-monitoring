locals {
  lambda_name = "${var.project_name}-${var.environment}-stock-info"
}

# Archive the Python file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/stock_lambda.zip"
}

# Add this data source to get the Datadog API key
data "aws_secretsmanager_secret" "datadog_api_key" {
  name = "poc_datadog/datadog/api_key"
}

data "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id = data.aws_secretsmanager_secret.datadog_api_key.id
}

# Lambda function
resource "aws_lambda_function" "stock_info" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = local.lambda_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.handler"
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      ENVIRONMENT = var.environment
      DD_LAMBDA_HANDLER = "main.handler"
      DD_TRACE_ENABLED = "true"
      DD_MERGE_XRAY_TRACES = "true"
      DD_SERVICE = local.lambda_name
      DD_ENV = var.environment
      DD_VERSION = var.function_version
      DD_API_KEY = data.aws_secretsmanager_secret_version.datadog_api_key.secret_string
      DD_LOG_LEVEL = "debug"
      DD_TRACE_DEBUG = "true"
    }
  }

  layers = [
    "arn:aws:lambda:${data.aws_region.current.name}:464622532012:layer:Datadog-Python39:58" # Datadog Lambda Layer
  ]

  tags = var.tags
}

# REST API Gateway instead of HTTP API
resource "aws_api_gateway_rest_api" "stock_api" {
  name = "${local.lambda_name}-api"

  tags = var.tags
}

# API Resource
resource "aws_api_gateway_resource" "stock" {
  rest_api_id = aws_api_gateway_rest_api.stock_api.id
  parent_id   = aws_api_gateway_rest_api.stock_api.root_resource_id
  path_part   = "stock"
}

# API Method
resource "aws_api_gateway_method" "get_stock" {
  rest_api_id      = aws_api_gateway_rest_api.stock_api.id
  resource_id      = aws_api_gateway_resource.stock.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = var.api_key_required
}

# Lambda Integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.stock_api.id
  resource_id = aws_api_gateway_resource.stock.id
  http_method = aws_api_gateway_method.get_stock.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.stock_info.invoke_arn
}

# Lambda Permission
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stock_info.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.stock_api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "stock_api" {
  rest_api_id = aws_api_gateway_rest_api.stock_api.id

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_account.main,
    aws_iam_role_policy.api_gateway_cloudwatch
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "stock_api" {
  deployment_id = aws_api_gateway_deployment.stock_api.id
  rest_api_id   = aws_api_gateway_rest_api.stock_api.id
  stage_name    = var.environment

  depends_on = [
    aws_api_gateway_account.main,
    aws_iam_role_policy.api_gateway_cloudwatch
  ]

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      responseTime   = "$context.responseLatency"
      # Datadog specific fields
      dd = {
        service = "api-gateway"
        env     = var.environment
        tags    = ["service:api-gateway", "resource:/stock"]
      }
    })
  }

  tags = var.tags
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "stock_api" {
  count = var.api_key_required ? 1 : 0

  name = "${local.lambda_name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.stock_api.id
    stage  = aws_api_gateway_stage.stock_api.stage_name
  }

  tags = var.tags
}

# API Key
resource "aws_api_gateway_api_key" "stock_api_key" {
  count = var.api_key_required ? 1 : 0

  name  = "${local.lambda_name}-key"
  value = data.aws_secretsmanager_secret_version.api_key.secret_string
}

# Associate API Key with Usage Plan
resource "aws_api_gateway_usage_plan_key" "stock_api" {
  count = var.api_key_required ? 1 : 0

  key_id        = aws_api_gateway_api_key.stock_api_key[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.stock_api[0].id
}

# IAM role for API Gateway CloudWatch logging
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${local.lambda_name}-apigw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for the API Gateway role
resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name = "${local.lambda_name}-apigw-policy"
  role = aws_iam_role.api_gateway_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# API Gateway account settings
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# Add subscription filter to forward logs to Datadog
resource "aws_cloudwatch_log_subscription_filter" "api_gateway_logs_to_datadog" {
  name            = "${local.lambda_name}-api-logs-filter"
  log_group_name  = aws_cloudwatch_log_group.api_logs.name
  filter_pattern  = ""  # Empty pattern to capture all logs
  destination_arn = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:datadog-forwarder"
}