# CodeBuild project for React frontend
resource "aws_codebuild_project" "frontend" {
  name         = "${var.project_name}-${var.environment}-frontend-build"
  description  = "Build project for ${var.project_name} ${var.environment} React frontend"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "NODE_ENV"
      value = var.environment == "prod" ? "production" : var.environment
    }

    environment_variable {
      name  = "REACT_APP_API_URL"
      value = var.api_gateway_url
    }

    environment_variable {
      name  = "S3_BUCKET"
      value = var.frontend_bucket_name
    }

    environment_variable {
      name  = "CLOUDFRONT_DISTRIBUTION_ID"
      value = var.cloudfront_distribution_id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = var.tags
}

# CodePipeline for React frontend deployment
resource "aws_codepipeline" "frontend" {
  name     = "${var.project_name}-${var.environment}-frontend-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.artifacts_bucket_name
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.codepipeline.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_repo_owner
        Repo       = var.github_repo_name
        Branch     = var.github_branch
        OAuthToken = var.github_oauth_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.frontend.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        BucketName = var.frontend_bucket_name
        Extract    = "true"
      }
    }
  }

  tags = var.tags
}

# KMS key for CodePipeline encryption
resource "aws_kms_key" "codepipeline" {
  description             = "KMS key for ${var.project_name} ${var.environment} CodePipeline"
  deletion_window_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-codepipeline-key"
  })
}

resource "aws_kms_alias" "codepipeline" {
  name          = "alias/${var.project_name}-${var.environment}-codepipeline"
  target_key_id = aws_kms_key.codepipeline.key_id
}

# CloudWatch Log Group for CodeBuild
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-frontend-build"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
