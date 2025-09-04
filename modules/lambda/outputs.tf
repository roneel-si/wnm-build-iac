# Dynamic function outputs
output "lambda_functions" {
  description = "All Lambda functions created by this module"
  value       = aws_lambda_function.functions
}

# Backwards compatibility outputs for existing usage
output "lambda_function_name" {
  description = "Name of the API Lambda function"
  value       = local.api_function.function_name
}

output "lambda_function_arn" {
  description = "ARN of the API Lambda function"
  value       = local.api_function.arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the API Lambda function"
  value       = local.api_function.invoke_arn
}

output "background_lambda_function_name" {
  description = "Name of the background Lambda function"
  value       = local.background_function.function_name
}

output "background_lambda_function_arn" {
  description = "ARN of the background Lambda function"
  value       = local.background_function.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}
