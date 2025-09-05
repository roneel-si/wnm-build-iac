# CodeStar Connection for GitHub v2 integration
resource "aws_codestarconnections_connection" "github" {
  count = var.codestar_connection.create_connection ? 1 : 0

  name          = var.codestar_connection.connection_name != "" ? var.codestar_connection.connection_name : "${var.project_name}-${var.environment}-github-connection"
  provider_type = var.codestar_connection.provider_type

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-github-connection"
  })
}

# Create KMS key for CodePipeline encryption
resource "aws_kms_key" "codepipeline" {
  count = var.kms_config.create_kms_key ? 1 : 0
  
  description             = var.kms_config.description != "" ? var.kms_config.description : "KMS key for ${var.project_name} ${var.environment} CodePipeline"
  deletion_window_in_days = var.kms_config.deletion_window
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CodePipeline to use the key"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-codepipeline-key"
  })
}

# KMS Key Alias
resource "aws_kms_alias" "codepipeline" {
  count = var.kms_config.create_kms_key ? 1 : 0
  
  name          = "alias/${var.project_name}-${var.environment}-codepipeline"
  target_key_id = aws_kms_key.codepipeline[0].key_id
}

# CloudWatch Log Groups for CodeBuild projects
resource "aws_cloudwatch_log_group" "codebuild" {
  for_each = var.cloudwatch_logs.enabled ? var.codebuild_projects : {}
  
  name              = var.cloudwatch_logs.log_group_name != "" ? var.cloudwatch_logs.log_group_name : "/aws/codebuild/${var.project_name}-${var.environment}-${each.key}"
  retention_in_days = var.cloudwatch_logs.retention_days
  
  tags = var.tags
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  count = var.iam_config.codepipeline_role.create_role ? 1 : 0
  
  name = "${var.project_name}-${var.environment}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  count = var.iam_config.codebuild_role.create_role ? 1 : 0
  
  name = "${var.project_name}-${var.environment}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Dynamic CodeBuild Projects
resource "aws_codebuild_project" "projects" {
  for_each = var.codebuild_projects

  name         = "${var.project_name}-${var.environment}-${each.key}"
  description  = each.value.description != "" ? each.value.description : "Build project for ${var.project_name} ${var.environment} ${each.key}"
  service_role = each.value.service_role_arn != "" ? each.value.service_role_arn : (var.iam_config.codebuild_role.create_role ? aws_iam_role.codebuild_role[0].arn : var.iam_config.codebuild_role.role_arn)

  # Artifacts
  artifacts {
    type                = each.value.artifacts.type
    location            = each.value.artifacts.location != "" ? each.value.artifacts.location : null
    name                = each.value.artifacts.name != "" ? each.value.artifacts.name : null
    namespace_type      = each.value.artifacts.namespace_type
    packaging           = each.value.artifacts.packaging
    path                = each.value.artifacts.path != "" ? each.value.artifacts.path : null
  }

  # Environment
  environment {
    compute_type                = each.value.environment.compute_type
    image                      = each.value.environment.image
    type                       = each.value.environment.type
    image_pull_credentials_type = each.value.environment.image_pull_credentials_type
    privileged_mode            = each.value.environment.privileged_mode

    # Dynamic Environment Variables
    dynamic "environment_variable" {
      for_each = each.value.environment.environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  # Source
  source {
    type      = each.value.source.type
    buildspec = each.value.source.buildspec
    location  = each.value.source.location != "" ? each.value.source.location : null
  }

  # Cache
  dynamic "cache" {
    for_each = each.value.cache.type != "NO_CACHE" ? [each.value.cache] : []
    content {
      type     = cache.value.type
      location = cache.value.location
      modes    = cache.value.modes
    }
  }

  # VPC Config
  dynamic "vpc_config" {
    for_each = each.value.vpc_config != null ? [each.value.vpc_config] : []
    content {
      vpc_id             = vpc_config.value.vpc_id
      subnets            = vpc_config.value.subnets
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Logs
  logs_config {
    dynamic "cloudwatch_logs" {
      for_each = each.value.logs_config.cloudwatch_logs.status == "ENABLED" ? [each.value.logs_config.cloudwatch_logs] : []
      content {
        status      = cloudwatch_logs.value.status
        group_name  = cloudwatch_logs.value.group_name != "" ? cloudwatch_logs.value.group_name : aws_cloudwatch_log_group.codebuild[each.key].name
        stream_name = cloudwatch_logs.value.stream_name
      }
    }

    dynamic "s3_logs" {
      for_each = each.value.logs_config.s3_logs.status == "ENABLED" ? [each.value.logs_config.s3_logs] : []
      content {
        status              = s3_logs.value.status
        location            = s3_logs.value.location
        encryption_disabled = s3_logs.value.encryption_disabled
      }
    }
  }

  build_timeout  = each.value.build_timeout
  queued_timeout = each.value.queued_timeout

  tags = var.tags
}

# Local processing for automatic GitHub v2 upgrade
locals {
  # Get CodeStar connection ARN (either created or provided)
  codestar_connection_arn = var.codestar_connection.create_connection ? aws_codestarconnections_connection.github[0].arn : var.codestar_connection.connection_arn
  
  # Process pipeline stages to automatically upgrade GitHub v1 to v2
  processed_pipeline_stages = [
    for stage in var.pipeline_stages : {
      name = stage.name
      actions = [
        for action in stage.actions : {
          name             = action.name
          category         = action.category
          # Automatically upgrade GitHub v1 to v2 if CodeStar connection is available
          owner            = (action.provider == "GitHub" && local.codestar_connection_arn != "") ? "AWS" : action.owner
          provider         = (action.provider == "GitHub" && local.codestar_connection_arn != "") ? "CodeStarSourceConnection" : action.provider
          version          = action.version
          input_artifacts  = action.input_artifacts
          output_artifacts = action.output_artifacts
          region           = action.region
          role_arn         = action.role_arn
          run_order        = action.run_order
          # Transform GitHub v1 configuration to v2 format
          configuration = (action.provider == "GitHub" && local.codestar_connection_arn != "") ? {
            ConnectionArn        = local.codestar_connection_arn
            FullRepositoryId     = "${lookup(action.configuration, "Owner", "")}/${lookup(action.configuration, "Repo", "")}"
            BranchName          = lookup(action.configuration, "Branch", "main")
            OutputArtifactFormat = "CODE_ZIP"
          } : action.configuration
        }
      ]
    }
  ]
}

# CodePipeline
resource "aws_codepipeline" "main" {
  name         = var.pipeline_config.name != "" ? var.pipeline_config.name : "${var.project_name}-${var.environment}-pipeline"
  role_arn     = var.pipeline_config.role_arn != "" ? var.pipeline_config.role_arn : (var.iam_config.codepipeline_role.create_role ? aws_iam_role.codepipeline_role[0].arn : var.iam_config.codepipeline_role.role_arn)
  pipeline_type = var.pipeline_config.pipeline_type
  execution_mode = var.pipeline_config.execution_mode

  artifact_store {
    location = var.artifact_store.location
    type     = var.artifact_store.type
    region   = var.artifact_store.region

    dynamic "encryption_key" {
      for_each = var.artifact_store.kms_key_id != "" ? [var.artifact_store.kms_key_id] : (var.kms_config.create_kms_key ? [aws_kms_key.codepipeline[0].arn] : [])
      content {
        id   = encryption_key.value
        type = "KMS"
      }
    }
  }

  # Dynamic Pipeline Stages (with automatic GitHub v2 upgrade)
  dynamic "stage" {
    for_each = local.processed_pipeline_stages
    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          input_artifacts  = action.value.input_artifacts
          output_artifacts = action.value.output_artifacts
          configuration    = action.value.configuration
          region           = action.value.region
          role_arn         = action.value.role_arn
          run_order        = action.value.run_order
        }
      }
    }
  }

  tags = var.tags
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}