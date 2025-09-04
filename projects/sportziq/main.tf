terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

locals {
  project_name = "sportziq"
  common_tags = merge(var.common_tags, {
    Project     = local.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  project_name = local.project_name
  environment  = var.environment
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  tags = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"
  
  project_name = local.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  
  tags = local.common_tags
}

# S3 Buckets Module
module "s3" {
  source = "../../modules/s3"
  
  project_name = local.project_name
  environment  = var.environment
  
  tags = local.common_tags
}

# Lambda Module
module "lambda" {
  source = "../../modules/lambda"
  
  project_name = local.project_name
  environment  = var.environment
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  lambda_sg_id       = module.security_groups.lambda_security_group_id
  
  tags = local.common_tags
}

# API Gateway Module
module "api_gateway" {
  source = "../../modules/api-gateway"
  
  project_name = local.project_name
  environment  = var.environment
  
  lambda_function_arn = module.lambda.lambda_function_arn
  
  tags = local.common_tags
}

# CloudFront Module
module "cloudfront" {
  source = "../../modules/cloudfront"
  
  project_name = local.project_name
  environment  = var.environment
  
  s3_bucket_domain_name = module.s3.website_bucket_domain_name
  api_gateway_domain    = module.api_gateway.api_gateway_domain
  
  tags = local.common_tags
}

# CodePipeline Module
module "codepipeline" {
  source = "../../modules/codepipeline"
  
  project_name = local.project_name
  environment  = var.environment
  
  frontend_bucket_name = module.s3.website_bucket_name
  lambda_function_name = module.lambda.lambda_function_name
  
  github_repo_owner  = var.github_repo_owner
  github_repo_name   = var.github_repo_name
  github_branch      = var.github_branch
  
  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"
  
  project_name = local.project_name
  environment  = var.environment
  
  api_gateway_name      = module.api_gateway.api_gateway_name
  lambda_function_name  = module.lambda.lambda_function_name
  cloudfront_id         = module.cloudfront.cloudfront_distribution_id
  
  tags = local.common_tags
}
