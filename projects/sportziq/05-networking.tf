# =============================================================================
# NETWORKING - API Gateway, CloudFront, and networking resources  
# =============================================================================

# API Gateway for Lambda functions
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name = local.project_name
  environment  = var.environment

  lambda_function_arn        = module.lambda.lambda_function_arn
  lambda_function_invoke_arn = module.lambda.lambda_function_invoke_arn

  tags = local.common_tags
}

# CloudFront CDN for global distribution
module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name = local.project_name
  environment  = var.environment

  s3_bucket_domain_name = module.s3.website_bucket_domain_name
  api_gateway_domain    = module.api_gateway.api_gateway_domain
  api_gateway_stage     = var.environment

  tags = local.common_tags
}
