output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.stock_info.function_name
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${aws_api_gateway_stage.stock_api.invoke_url}/stock"
}

output "api_key" {
  description = "API Key for authentication"
  value       = var.api_key_required ? aws_api_gateway_api_key.stock_api_key[0].value : null
  sensitive   = true
} 