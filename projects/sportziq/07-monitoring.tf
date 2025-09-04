# =============================================================================
# MONITORING - CloudWatch, alarms, and observability
# =============================================================================

# TODO: Uncomment when monitoring module is ready
# module "monitoring" {
#   source = "../../modules/monitoring"
#
#   project_name = local.project_name
#   environment  = var.environment
#
#   api_gateway_name      = module.api_gateway.api_gateway_name
#   lambda_function_name  = module.lambda.lambda_function_name
#   cloudfront_id         = module.cloudfront.cloudfront_distribution_id
#
#   tags = local.common_tags
# }
