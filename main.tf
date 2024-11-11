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

module "nginx_service" {
  source = "./modules/nginx-service"

  project_name    = var.project_name
  environment     = var.environment
  cluster_id      = module.ecs.cluster_id
  vpc_id          = data.aws_vpc.default.id
  private_subnets = data.aws_subnets.default.ids
  public_subnets  = data.aws_subnets.public.ids

  # Optional configurations
  container_port = 80
  cpu           = 256
  memory        = 512
  desired_count = 2

  datadog_api_key = var.datadog_api_key
  datadog_region  = var.datadog_region

  tags = local.resource_tags
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get public subnets
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
} 