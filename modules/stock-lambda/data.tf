# Get the API key from Secrets Manager
data "aws_secretsmanager_secret" "api_key" {
  name = var.api_key_secret_name
}

data "aws_secretsmanager_secret_version" "api_key" {
  secret_id = data.aws_secretsmanager_secret.api_key.id
}

# Get current region
data "aws_region" "current" {} 