variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# GitHub Configuration
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
  description = "GitHub OAuth token for CodePipeline"
  type        = string
  sensitive   = true
}

# S3 Configuration
variable "artifacts_bucket_name" {
  description = "Name of S3 bucket for CodePipeline artifacts"
  type        = string
}

variable "frontend_bucket_name" {
  description = "Name of S3 bucket for frontend hosting"
  type        = string
}

# API Gateway Configuration
variable "api_gateway_url" {
  description = "API Gateway URL for React app"
  type        = string
}

# CloudFront Configuration
variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  type        = string
  default     = ""
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN for IAM permissions"
  type        = string
  default     = "*"
}

# CodeBuild Configuration
variable "codebuild_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "codebuild_image" {
  description = "CodeBuild Docker image"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

# Logging Configuration
variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}
