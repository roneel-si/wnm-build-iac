# =============================================================================
# CI/CD - CodePipeline and deployment automation
# =============================================================================

module "codepipeline" {
  source = "../../modules/codepipeline"

  project_name = local.project_name
  environment  = var.environment

  # S3 Configuration
  frontend_bucket_name  = module.s3.website_bucket_name
  artifacts_bucket_name = module.s3.codepipeline_artifacts_bucket_name

  # API Gateway Configuration
  api_gateway_url = module.api_gateway.api_gateway_url

  # CloudFront Configuration
  cloudfront_distribution_id  = module.cloudfront.cloudfront_distribution_id
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn

  # GitHub Configuration
  github_repo_owner  = var.github_repo_owner
  github_repo_name   = var.github_repo_name
  github_branch      = var.github_branch
  github_oauth_token = var.github_oauth_token

  tags = local.common_tags
}
