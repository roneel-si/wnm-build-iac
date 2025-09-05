# =============================================================================
# CI/CD - CodePipeline and deployment automation
# =============================================================================

module "codepipeline" {
  source = "../../modules/codepipeline"

  project_name = local.project_name
  environment  = var.environment

  # Generic Pipeline Configuration for SportzIQ
  pipeline_config = {
    name        = "sportziq-${var.environment}-frontend-pipeline"
    description = "SportzIQ ${var.environment} React frontend deployment pipeline"
  }

  # Artifact Store Configuration
  artifact_store = {
    location   = module.s3.codepipeline_artifacts_bucket_name
    type       = "S3"
    kms_key_id = ""  # Will use auto-created KMS key
  }

  # Source Configuration for SportzIQ (GitHub v2 with CodeStar Connection)
  source_config = {
    provider = "GitHub"  # Will be automatically upgraded to CodeStarSourceConnection
    configuration = {
      Owner      = var.github_repo_owner
      Repo       = var.github_repo_name
      Branch     = var.github_branch
      OAuthToken = var.github_oauth_token  # Only used if CodeStar connection not available
    }
    output_artifacts = ["source_output"]
  }

  # CodeStar Connection for GitHub v2 (recommended)
  codestar_connection = {
    create_connection = true
    connection_name   = "sportziq-${var.environment}-github"
    provider_type     = "GitHub"
  }

  # CodeBuild Projects for SportzIQ
  codebuild_projects = {
    frontend_build = {
      description = "Build SportzIQ ${var.environment} React frontend"
      
      environment = {
        compute_type = "BUILD_GENERAL1_SMALL"
        image        = "aws/codebuild/standard:7.0"
        type         = "LINUX_CONTAINER"
        
        # SportzIQ-specific environment variables
        environment_variables = {
          NODE_ENV                   = var.environment == "prod" ? "production" : var.environment
          REACT_APP_API_URL         = module.api_gateway.api_gateway_url
          REACT_APP_ENVIRONMENT     = var.environment
          REACT_APP_PROJECT         = local.project_name
          REACT_APP_VERSION         = "1.0.0"
          REACT_APP_GAME_MODE       = var.environment == "prod" ? "tournament" : "casual"
          REACT_APP_MAX_PLAYERS     = "8"
          S3_BUCKET                 = module.s3.website_bucket_name
          CLOUDFRONT_DISTRIBUTION_ID = module.cloudfront.cloudfront_distribution_id
        }
      }
      
      cache = {
        type  = "LOCAL"
        modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
      }
      
      source = {
        type      = "CODEPIPELINE"
        buildspec = "buildspec.yml"
      }
      
      build_timeout  = var.environment == "prod" ? 10 : 5  # Minutes
      queued_timeout = 60
    }
  }

  # Dynamic Pipeline Stages for SportzIQ
  # Note: GitHub v1 provider will be automatically upgraded to v2 (CodeStarSourceConnection) 
  # when CodeStar connection is configured above
  pipeline_stages = [
    {
      name = "Source"
      actions = [
        {
          name             = "SourceAction"
          category         = "Source"
          owner            = "ThirdParty"  # Will be auto-changed to "AWS" for GitHub v2
          provider         = "GitHub"     # Will be auto-changed to "CodeStarSourceConnection" for GitHub v2
          version          = "1"
          output_artifacts = ["source_output"]
          configuration = {
            Owner      = var.github_repo_owner
            Repo       = var.github_repo_name
            Branch     = var.github_branch
            OAuthToken = var.github_oauth_token  # Not used with GitHub v2
          }
        }
      ]
    },
    {
      name = "Build"
      actions = [
        {
          name             = "BuildAction"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          input_artifacts  = ["source_output"]
          output_artifacts = ["build_output"]
          version          = "1"
          configuration = {
            ProjectName = "${local.project_name}-${var.environment}-frontend_build"  # Will be created dynamically
          }
        }
      ]
    },
    {
      name = "Deploy"
      actions = [
        {
          name            = "DeployToS3"
          category        = "Deploy"
          owner           = "AWS"
          provider        = "S3"
          input_artifacts = ["build_output"]
          version         = "1"
          configuration = {
            BucketName = module.s3.website_bucket_name
            Extract    = "true"
          }
        }
      ]
    }
  ]

  # CloudWatch Logs Configuration for SportzIQ
  cloudwatch_logs = {
    enabled        = true
    retention_days = var.environment == "prod" ? 30 : 7
  }

  # IAM Configuration for SportzIQ
  iam_config = {
    codepipeline_role = {
      create_role = true
      policy_arns = []
      inline_policies = {
        # Additional permissions for CloudFront invalidation
        cloudfront_invalidation = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "cloudfront:CreateInvalidation",
                "cloudfront:GetInvalidation",
                "cloudfront:ListInvalidations"
              ]
              Resource = module.cloudfront.cloudfront_distribution_arn
            }
          ]
        })
      }
    }
    codebuild_role = {
      create_role = true
      policy_arns = []
      inline_policies = {
        # S3 deployment permissions
        s3_deployment = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
              ]
              Resource = [
                module.s3.website_bucket_arn,
                "${module.s3.website_bucket_arn}/*"
              ]
            }
          ]
        })
      }
    }
  }

  # KMS Configuration for SportzIQ
  kms_config = {
    create_kms_key  = true
    description     = "KMS key for SportzIQ ${var.environment} CodePipeline encryption"
    deletion_window = var.environment == "prod" ? 30 : 7
  }

  tags = local.common_tags
}
