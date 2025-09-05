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

# Generic Pipeline Configuration
variable "pipeline_config" {
  description = "CodePipeline configuration"
  type = object({
    name         = optional(string, "")
    description  = optional(string, "")
    role_arn     = optional(string, "")
    pipeline_type = optional(string, "V1")
    execution_mode = optional(string, "SUPERSEDED")
  })
  default = {}
}

# Artifact Store Configuration
variable "artifact_store" {
  description = "CodePipeline artifact store configuration"
  type = object({
    location = string
    type     = optional(string, "S3")
    kms_key_id = optional(string, "")
    region   = optional(string, "")
  })
}

# Generic Source Configuration
variable "source_config" {
  description = "Source stage configuration"
  type = object({
    provider = string  # GitHub, GitHubV2, S3, CodeCommit, etc.
    configuration = map(string)
    output_artifacts = optional(list(string), ["source_output"])
    version = optional(string, "1")
  })
}

# CodeStar Connection Configuration (for GitHub v2)
variable "codestar_connection" {
  description = "CodeStar connection configuration for GitHub v2 integration"
  type = object({
    create_connection = optional(bool, false)
    connection_name   = optional(string, "")
    provider_type     = optional(string, "GitHub")
    connection_arn    = optional(string, "")
  })
  default = {
    create_connection = false
  }
}

# Generic CodeBuild Projects Configuration
variable "codebuild_projects" {
  description = "CodeBuild projects configuration"
  type = map(object({
    description = optional(string, "")
    service_role_arn = optional(string, "")
    
    # Build Environment
    environment = object({
      compute_type                = optional(string, "BUILD_GENERAL1_SMALL")
      image                      = optional(string, "aws/codebuild/standard:7.0")
      type                       = optional(string, "LINUX_CONTAINER")
      image_pull_credentials_type = optional(string, "CODEBUILD")
      privileged_mode            = optional(bool, false)
      environment_variables      = optional(map(string), {})
    })
    
    # Artifacts
    artifacts = optional(object({
      type     = optional(string, "CODEPIPELINE")
      location = optional(string, "")
      name     = optional(string, "")
      namespace_type = optional(string, "NONE")
      packaging = optional(string, "NONE")
      path     = optional(string, "")
    }), { type = "CODEPIPELINE", namespace_type = "NONE", packaging = "NONE" })
    
    # Cache
    cache = optional(object({
      type     = optional(string, "NO_CACHE")
      location = optional(string, "")
      modes    = optional(list(string), [])
    }), { type = "NO_CACHE" })
    
    # Source
    source = optional(object({
      type      = optional(string, "CODEPIPELINE")
      buildspec = optional(string, "buildspec.yml")
      location  = optional(string, "")
    }), { type = "CODEPIPELINE", buildspec = "buildspec.yml" })
    
    # Timeout
    build_timeout    = optional(number, 60)
    queued_timeout   = optional(number, 480)
    
    # VPC Config (optional)
    vpc_config = optional(object({
      vpc_id             = string
      subnets            = list(string)
      security_group_ids = list(string)
    }), null)
    
    # Logs
    logs_config = optional(object({
      cloudwatch_logs = optional(object({
        status      = optional(string, "ENABLED")
        group_name  = optional(string, "")
        stream_name = optional(string, "")
      }), { status = "ENABLED" })
      s3_logs = optional(object({
        status              = optional(string, "DISABLED")
        location            = optional(string, "")
        encryption_disabled = optional(bool, false)
      }), { status = "DISABLED" })
    }), { cloudwatch_logs = { status = "ENABLED" } })
  }))
  default = {}
}

# Generic Pipeline Stages Configuration
variable "pipeline_stages" {
  description = "CodePipeline stages configuration"
  type = list(object({
    name = string
    actions = list(object({
      name             = string
      category         = string  # Source, Build, Test, Deploy, Approval, Invoke
      owner            = string  # AWS, ThirdParty, Custom
      provider         = string  # GitHub, CodeBuild, S3, Lambda, etc.
      version          = optional(string, "1")
      input_artifacts  = optional(list(string), [])
      output_artifacts = optional(list(string), [])
      configuration    = map(string)
      region           = optional(string, "")
      role_arn         = optional(string, "")
      run_order        = optional(number, 1)
    }))
  }))
}

# CloudWatch Logs Configuration
variable "cloudwatch_logs" {
  description = "CloudWatch logs configuration for CodeBuild projects"
  type = object({
    enabled         = optional(bool, true)
    retention_days  = optional(number, 14)
    log_group_name  = optional(string, "")
  })
  default = {
    enabled = true
    retention_days = 14
  }
}

# IAM Configuration  
variable "iam_config" {
  description = "IAM configuration for CodePipeline and CodeBuild"
  type = object({
    # CodePipeline Role
    codepipeline_role = optional(object({
      create_role = optional(bool, true)
      role_arn    = optional(string, "")
      policy_arns = optional(list(string), [])
      inline_policies = optional(map(string), {})
    }), { create_role = true })
    
    # CodeBuild Role
    codebuild_role = optional(object({
      create_role = optional(bool, true)  
      role_arn    = optional(string, "")
      policy_arns = optional(list(string), [])
      inline_policies = optional(map(string), {})
    }), { create_role = true })
  })
  default = {
    codepipeline_role = { create_role = true }
    codebuild_role    = { create_role = true }
  }
}

# KMS Configuration
variable "kms_config" {
  description = "KMS configuration for CodePipeline encryption"
  type = object({
    create_kms_key = optional(bool, true)
    kms_key_arn    = optional(string, "")
    description    = optional(string, "")
    deletion_window = optional(number, 7)
  })
  default = {
    create_kms_key = true
  }
}

# Legacy variables for backward compatibility (will be deprecated)
variable "github_repo_owner" {
  description = "[DEPRECATED] Use source_config instead. GitHub repository owner"
  type        = string
  default     = ""
}

variable "github_repo_name" {
  description = "[DEPRECATED] Use source_config instead. GitHub repository name" 
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "[DEPRECATED] Use source_config instead. GitHub branch to deploy from"
  type        = string
  default     = "main"
}

variable "github_oauth_token" {
  description = "[DEPRECATED] Use source_config instead. GitHub OAuth token"
  type        = string
  default     = ""
  sensitive   = true
}