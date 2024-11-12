output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.ecs.cloudwatch_log_group_name
}

output "nginx_alb_dns_name" {
  description = "DNS name of the Nginx load balancer"
  value       = module.nginx_service.alb_dns_name
}

output "nginx_service_name" {
  description = "Name of the Nginx ECS service"
  value       = module.nginx_service.service_name
}

output "stock_api_endpoint" {
  description = "Stock API endpoint URL"
  value       = module.stock_lambda.api_endpoint
}

output "stock_api_key" {
  description = "Stock API Key"
  value       = module.stock_lambda.api_key
  sensitive   = true
} 