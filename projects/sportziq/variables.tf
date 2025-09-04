variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# VPC Configuration - Removed for serverless architecture
# Keeping variables commented for potential future use if database access is needed
# 
# variable "vpc_cidr" {
#   description = "CIDR block for VPC"
#   type        = string
#   default     = "10.0.0.0/16"
# }
# 
# variable "availability_zones" {
#   description = "List of availability zones"
#   type        = list(string)
#   default     = ["us-east-1a", "us-east-1b"]
# }
# 
# variable "public_subnet_cidrs" {
#   description = "CIDR blocks for public subnets"
#   type        = list(string)
#   default     = ["10.0.1.0/24", "10.0.2.0/24"]
# }
# 
# variable "private_subnet_cidrs" {
#   description = "CIDR blocks for private subnets"
#   type        = list(string)
#   default     = ["10.0.10.0/24", "10.0.20.0/24"]
# }

# GitHub Configuration for CodePipeline
variable "github_repo_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to deploy from"
  type        = string
  default     = "main"
}

variable "github_oauth_token" {
  description = "GitHub OAuth token for CodePipeline access"
  type        = string
  sensitive   = true
}
