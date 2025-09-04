# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Attach VPC execution policy
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Custom IAM policies (configured from project level)
resource "aws_iam_role_policy" "lambda_custom_policies" {
  for_each = var.lambda_iam_policies

  name   = "${var.project_name}-${var.environment}-${each.key}"
  role   = aws_iam_role.lambda_role.id
  policy = each.value
}

# Dynamic Lambda functions
resource "aws_lambda_function" "functions" {
  for_each = var.lambda_functions

  function_name = "${var.project_name}-${var.environment}-${each.key}"
  role          = aws_iam_role.lambda_role.arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  timeout       = each.value.timeout
  memory_size   = each.value.memory_size

  filename         = each.value.zip_file != "" ? each.value.zip_file : (each.value.s3_bucket != "" ? null : "../../modules/lambda/dummy-lambda.zip")
  s3_bucket        = each.value.s3_bucket != "" ? each.value.s3_bucket : null
  s3_key           = each.value.s3_key != "" ? each.value.s3_key : null
  source_code_hash = each.value.zip_file != "" ? filebase64sha256(each.value.zip_file) : (each.value.s3_bucket != "" ? null : filebase64sha256("../../modules/lambda/dummy-lambda.zip"))

  # VPC configuration - only if VPC is provided
  dynamic "vpc_config" {
    for_each = var.vpc_id != "" ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [var.lambda_sg_id]
    }
  }

  # Environment variables - only if provided
  dynamic "environment" {
    for_each = length(each.value.environment_variables) > 0 ? [1] : []
    content {
      variables = each.value.environment_variables
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}"
  })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_vpc_execution,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# Backwards compatibility - reference specific functions for outputs
locals {
  api_function        = aws_lambda_function.functions["api"]
  background_function = aws_lambda_function.functions["background"]
}

# Dynamic CloudWatch Log Groups for each Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = var.lambda_functions

  name              = "/aws/lambda/${var.project_name}-${var.environment}-${each.key}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
