# =============================================================================
# STORAGE - S3 Buckets and related storage resources
# =============================================================================

module "s3" {
  source = "../../modules/s3"

  project_name = local.project_name
  environment  = var.environment

  tags = local.common_tags
}
