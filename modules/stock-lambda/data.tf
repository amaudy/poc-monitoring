# Get the API Gateway API key from Secrets Manager
data "aws_secretsmanager_secret" "api_key" {
  name = var.api_key_secret_name
}

data "aws_secretsmanager_secret_version" "api_key" {
  secret_id = data.aws_secretsmanager_secret.api_key.id
}

data "aws_secretsmanager_secret" "datadog_api_key" {
  name = var.datadog_api_key_secret_name
}

data "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id = data.aws_secretsmanager_secret.datadog_api_key.id
}

# Get current region
data "aws_region" "current" {}

# Add this to get the AWS account ID
data "aws_caller_identity" "current" {}

# Make the Datadog Forwarder data source conditional
data "aws_lambda_function" "datadog_forwarder" {
  count         = var.enable_datadog_forwarder ? 1 : 0
  function_name = var.datadog_forwarder_name
} 