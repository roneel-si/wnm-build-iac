# =============================================================================
# COMPUTE - Lambda functions and compute resources
# =============================================================================

module "lambda" {
  source = "../../modules/lambda"

  project_name = local.project_name
  environment  = var.environment

  # SportzIQ specific Lambda functions configuration
  lambda_functions = {
    api = {
      handler = "lambda_function.lambda_handler"
      runtime = "python3.9"
      timeout = 30
      memory_size = 128
      zip_file = "../../modules/lambda/dummy-lambda.zip"
      environment_variables = {
        ENVIRONMENT    = var.environment
        PROJECT        = local.project_name
        LOG_LEVEL      = "INFO"
        API_VERSION    = "v1"
        CORS_ORIGIN    = "*"
      }
    }
    background = {
      handler = "lambda_function.lambda_handler"
      runtime = "python3.9"
      timeout = 300
      memory_size = 256
      zip_file = "../../modules/lambda/dummy-lambda.zip"
      environment_variables = {
        ENVIRONMENT    = var.environment
        PROJECT        = local.project_name
        LOG_LEVEL      = "INFO"
        WORKER_TYPE    = "background"
        MAX_BATCH_SIZE = "10"
      }
    }
  }

  # SportzIQ specific IAM policies
  lambda_iam_policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource = [
            "${module.s3.website_bucket_arn}/*",
            "${module.s3.lambda_deployments_bucket_arn}/*"
          ]
        }
      ]
    })
    
    logs_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream", 
            "logs:PutLogEvents"
          ]
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })

    trivia_data_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:Query",
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem"
          ]
          Resource = "arn:aws:dynamodb:*:*:table/sportziq-*"
        }
      ]
    })
  }

  # Serverless configuration - no VPC for better performance
  # vpc_id             = module.vpc.vpc_id
  # private_subnet_ids = module.vpc.private_subnet_ids
  # lambda_sg_id       = module.security_groups.lambda_security_group_id

  tags = local.common_tags
}
