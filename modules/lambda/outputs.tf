output "lambda_function_name" {
  description = "Name of the API Lambda function"
  value       = aws_lambda_function.api.function_name
}

output "lambda_function_arn" {
  description = "ARN of the API Lambda function"
  value       = aws_lambda_function.api.arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the API Lambda function"
  value       = aws_lambda_function.api.invoke_arn
}

output "background_lambda_function_name" {
  description = "Name of the background Lambda function"
  value       = aws_lambda_function.background.function_name
}

output "background_lambda_function_arn" {
  description = "ARN of the background Lambda function"
  value       = aws_lambda_function.background.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}
