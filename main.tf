terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

module "ecs" {
  source = "./modules/ecs"

  cluster_name             = var.cluster_name
  enable_container_insights = true
  
  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
} 