# Get the API key from Secrets Manager
data "aws_secretsmanager_secret" "api_key" {
  name = var.api_key_secret_name
}

data "aws_secretsmanager_secret_version" "api_key" {
  secret_id = data.aws_secretsmanager_secret.api_key.id
}

# Get current region
data "aws_region" "current" {}

# Add this to get the AWS account ID
data "aws_caller_identity" "current" {} 