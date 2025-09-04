locals {
  project_name = "sportziq"

  common_tags = merge(var.common_tags, {
    Project     = local.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
