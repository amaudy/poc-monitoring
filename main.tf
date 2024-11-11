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
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      Terraform   = "true"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  resource_tags = merge(
    var.default_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Terraform   = "true"
      Name        = "${var.project_name}-${var.environment}"
    }
  )
}

module "ecs" {
  source = "./modules/ecs"

  cluster_name              = "${var.project_name}-${var.environment}"
  enable_container_insights = true
  project_name              = var.project_name

  tags = local.resource_tags
} 