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

# Custom policy for additional permissions
resource "aws_iam_role_policy" "lambda_custom_policy" {
  name = "${var.project_name}-${var.environment}-lambda-custom-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
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
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function for API
resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-${var.environment}-api"
  role         = aws_iam_role.lambda_role.arn
  handler      = var.lambda_handler
  runtime      = var.lambda_runtime
  timeout      = var.lambda_timeout
  memory_size  = var.lambda_memory_size

  filename         = var.lambda_zip_file != "" ? var.lambda_zip_file : null
  s3_bucket        = var.lambda_s3_bucket != "" ? var.lambda_s3_bucket : null
  s3_key          = var.lambda_s3_key != "" ? var.lambda_s3_key : null
  source_code_hash = var.lambda_zip_file != "" ? filebase64sha256(var.lambda_zip_file) : null

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = var.lambda_environment_variables
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-api"
  })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_vpc_execution,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# Lambda function for background tasks
resource "aws_lambda_function" "background" {
  function_name = "${var.project_name}-${var.environment}-background"
  role         = aws_iam_role.lambda_role.arn
  handler      = var.background_lambda_handler
  runtime      = var.lambda_runtime
  timeout      = var.background_lambda_timeout
  memory_size  = var.lambda_memory_size

  filename         = var.background_lambda_zip_file != "" ? var.background_lambda_zip_file : null
  s3_bucket        = var.lambda_s3_bucket != "" ? var.lambda_s3_bucket : null
  s3_key          = var.background_lambda_s3_key != "" ? var.background_lambda_s3_key : null
  source_code_hash = var.background_lambda_zip_file != "" ? filebase64sha256(var.background_lambda_zip_file) : null

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = var.lambda_environment_variables
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-background"
  })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_vpc_execution,
    aws_cloudwatch_log_group.background_lambda_logs
  ]
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-api"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "background_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-background"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
