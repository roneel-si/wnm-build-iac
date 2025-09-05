# CodePipeline Outputs
output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.main.name
}

output "codepipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.main.arn
}

output "codepipeline_id" {
  description = "ID of the CodePipeline"
  value       = aws_codepipeline.main.id
}

# Dynamic CodeBuild Projects Outputs
output "codebuild_projects" {
  description = "All CodeBuild projects created by this module"
  value       = aws_codebuild_project.projects
}

output "codebuild_project_names" {
  description = "Names of all CodeBuild projects"
  value       = { for k, v in aws_codebuild_project.projects : k => v.name }
}

output "codebuild_project_arns" {
  description = "ARNs of all CodeBuild projects"
  value       = { for k, v in aws_codebuild_project.projects : k => v.arn }
}

# IAM Role Outputs
output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline service role"
  value       = var.iam_config.codepipeline_role.create_role ? aws_iam_role.codepipeline_role[0].arn : var.iam_config.codepipeline_role.role_arn
}

output "codepipeline_role_name" {
  description = "Name of the CodePipeline service role"
  value       = var.iam_config.codepipeline_role.create_role ? aws_iam_role.codepipeline_role[0].name : null
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild service role"
  value       = var.iam_config.codebuild_role.create_role ? aws_iam_role.codebuild_role[0].arn : var.iam_config.codebuild_role.role_arn
}

output "codebuild_role_name" {
  description = "Name of the CodeBuild service role"
  value       = var.iam_config.codebuild_role.create_role ? aws_iam_role.codebuild_role[0].name : null
}

# KMS Outputs
output "kms_key_id" {
  description = "ID of the KMS key used for encryption (if created)"
  value       = var.kms_config.create_kms_key ? aws_kms_key.codepipeline[0].id : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = var.kms_config.create_kms_key ? aws_kms_key.codepipeline[0].arn : var.kms_config.kms_key_arn
}

output "kms_alias_name" {
  description = "Name of the KMS key alias (if created)"
  value       = var.kms_config.create_kms_key ? aws_kms_alias.codepipeline[0].name : null
}

# CloudWatch Logs Outputs
output "cloudwatch_log_groups" {
  description = "CloudWatch log groups for CodeBuild projects"
  value       = aws_cloudwatch_log_group.codebuild
}

output "cloudwatch_log_group_names" {
  description = "Names of CloudWatch log groups"
  value       = { for k, v in aws_cloudwatch_log_group.codebuild : k => v.name }
}

output "cloudwatch_log_group_arns" {
  description = "ARNs of CloudWatch log groups"
  value       = { for k, v in aws_cloudwatch_log_group.codebuild : k => v.arn }
}

# CodeStar Connection Outputs
output "codestar_connection_arn" {
  description = "ARN of the CodeStar connection (if created or provided)"
  value       = var.codestar_connection.create_connection ? aws_codestarconnections_connection.github[0].arn : var.codestar_connection.connection_arn
}

output "codestar_connection_status" {
  description = "Status of the CodeStar connection (if created)"
  value       = var.codestar_connection.create_connection ? aws_codestarconnections_connection.github[0].connection_status : null
}

output "codestar_connection_name" {
  description = "Name of the CodeStar connection (if created)"
  value       = var.codestar_connection.create_connection ? aws_codestarconnections_connection.github[0].name : null
}

# GitHub Integration Info
output "github_integration_type" {
  description = "Type of GitHub integration being used (v1 or v2)"
  value       = var.codestar_connection.create_connection || var.codestar_connection.connection_arn != "" ? "v2 (CodeStar)" : "v1 (OAuth)"
}

# Legacy outputs for backward compatibility
output "codebuild_project_name" {
  description = "[DEPRECATED] Use codebuild_project_names instead. Name of the first CodeBuild project"
  value       = length(keys(aws_codebuild_project.projects)) > 0 ? values(aws_codebuild_project.projects)[0].name : null
}

output "codebuild_project_arn" {
  description = "[DEPRECATED] Use codebuild_project_arns instead. ARN of the first CodeBuild project"
  value       = length(keys(aws_codebuild_project.projects)) > 0 ? values(aws_codebuild_project.projects)[0].arn : null
}