# Dynamic IAM Policy for CodePipeline
resource "aws_iam_role_policy" "codepipeline_policy" {
  count = var.iam_config.codepipeline_role.create_role ? 1 : 0
  
  name = "${var.project_name}-${var.environment}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        # Base CodePipeline permissions
        {
          Effect = "Allow"
          Action = [
            "s3:GetBucketVersioning",
            "s3:PutBucketVersioning",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:PutObject",
            "s3:DeleteObject"
          ]
          Resource = [
            "${local.artifact_bucket_arn}",
            "${local.artifact_bucket_arn}/*"
          ]
        },
        # CodeStar Connections permissions for GitHub v2
        {
          Effect = "Allow"
          Action = [
            "codestar-connections:UseConnection"
          ]
          Resource = var.codestar_connection.create_connection ? [aws_codestarconnections_connection.github[0].arn] : (var.codestar_connection.connection_arn != "" ? [var.codestar_connection.connection_arn] : [])
        },
        {
          Effect = "Allow"
          Action = [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild"
          ]
          Resource = local.codebuild_project_arns
        },
        {
          Effect = "Allow"
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Resource = local.kms_key_arn != "" ? [local.kms_key_arn] : []
        }
      ],
      # Additional permissions based on pipeline stages
      local.source_permissions,
      local.deploy_permissions
    )
  })
}

# Dynamic IAM Policy for CodeBuild
resource "aws_iam_role_policy" "codebuild_policy" {
  count = var.iam_config.codebuild_role.create_role ? 1 : 0
  
  name = "${var.project_name}-${var.environment}-codebuild-policy"
  role = aws_iam_role.codebuild_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        # Base CodeBuild permissions
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "arn:aws:logs:*:*:*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:PutObject"
          ]
          Resource = [
            "${local.artifact_bucket_arn}",
            "${local.artifact_bucket_arn}/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "kms:Encrypt",
            "kms:Decrypt", 
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Resource = local.kms_key_arn != "" ? [local.kms_key_arn] : []
        }
      ],
      # Additional permissions from build environment configurations
      local.codebuild_permissions
    )
  })
}

# Attach additional managed policies to CodePipeline role
resource "aws_iam_role_policy_attachment" "codepipeline_managed_policies" {
  count = var.iam_config.codepipeline_role.create_role ? length(var.iam_config.codepipeline_role.policy_arns) : 0
  
  role       = aws_iam_role.codepipeline_role[0].name
  policy_arn = var.iam_config.codepipeline_role.policy_arns[count.index]
}

# Attach additional managed policies to CodeBuild role
resource "aws_iam_role_policy_attachment" "codebuild_managed_policies" {
  count = var.iam_config.codebuild_role.create_role ? length(var.iam_config.codebuild_role.policy_arns) : 0
  
  role       = aws_iam_role.codebuild_role[0].name
  policy_arn = var.iam_config.codebuild_role.policy_arns[count.index]
}

# Attach additional inline policies to CodePipeline role
resource "aws_iam_role_policy" "codepipeline_inline_policies" {
  for_each = var.iam_config.codepipeline_role.create_role ? var.iam_config.codepipeline_role.inline_policies : {}
  
  name   = each.key
  role   = aws_iam_role.codepipeline_role[0].id
  policy = each.value
}

# Attach additional inline policies to CodeBuild role  
resource "aws_iam_role_policy" "codebuild_inline_policies" {
  for_each = var.iam_config.codebuild_role.create_role ? var.iam_config.codebuild_role.inline_policies : {}
  
  name   = each.key
  role   = aws_iam_role.codebuild_role[0].id
  policy = each.value
}

# Local values for dynamic policy generation
locals {
  # Artifact bucket ARN
  artifact_bucket_arn = "arn:aws:s3:::${var.artifact_store.location}"
  
  # KMS Key ARN
  kms_key_arn = var.kms_config.create_kms_key ? aws_kms_key.codepipeline[0].arn : var.kms_config.kms_key_arn
  
  # CodeBuild project ARNs  
  codebuild_project_arns = [
    for project_name in keys(var.codebuild_projects) :
    "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.project_name}-${var.environment}-${project_name}"
  ]
  
  # GitHub source permissions
  github_source_permissions = [
    for stage in var.pipeline_stages : [
      for action in stage.actions : {
        Effect = "Allow"
        Action = ["codepipeline:PollForSourceChanges"]
        Resource = "*"
      }
      if action.category == "Source" && action.provider == "GitHub"
    ]
  ]

  # S3 source permissions
  s3_source_permissions = [
    for stage in var.pipeline_stages : [
      for action in stage.actions : {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = lookup(action.configuration, "S3Bucket", "") != "" ? [
          "arn:aws:s3:::${lookup(action.configuration, "S3Bucket", "")}",
          "arn:aws:s3:::${lookup(action.configuration, "S3Bucket", "")}/*"
        ] : ["*"]
      }
      if action.category == "Source" && action.provider == "S3"
    ]
  ]

  # Combined source permissions
  source_permissions = flatten(concat(local.github_source_permissions, local.s3_source_permissions))
  
  # S3 deploy permissions
  s3_deploy_permissions = [
    for stage in var.pipeline_stages : [
      for action in stage.actions : {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:PutObjectAcl", "s3:DeleteObject"]
        Resource = lookup(action.configuration, "BucketName", "") != "" ? [
          "arn:aws:s3:::${lookup(action.configuration, "BucketName", "")}",
          "arn:aws:s3:::${lookup(action.configuration, "BucketName", "")}/*"
        ] : ["*"]
      }
      if action.category == "Deploy" && action.provider == "S3"
    ]
  ]

  # CloudFormation deploy permissions  
  cloudformation_deploy_permissions = [
    for stage in var.pipeline_stages : [
      for action in stage.actions : {
        Effect = "Allow"
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack", 
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate"
        ]
        Resource = "*"
      }
      if action.category == "Deploy" && action.provider == "CloudFormation"
    ]
  ]

  # Combined deploy permissions
  deploy_permissions = flatten(concat(local.s3_deploy_permissions, local.cloudformation_deploy_permissions))
  
  # CloudFront permissions for CodeBuild projects
  cloudfront_codebuild_permissions = [
    for project_name, project in var.codebuild_projects : {
      Effect = "Allow"
      Action = ["cloudfront:CreateInvalidation"]
      Resource = "*"
    }
    if contains(keys(project.environment.environment_variables), "CLOUDFRONT_DISTRIBUTION_ID")
  ]

  # Combined CodeBuild permissions
  codebuild_permissions = local.cloudfront_codebuild_permissions
}