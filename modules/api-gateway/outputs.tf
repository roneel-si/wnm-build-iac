output "api_gateway_id" {
  description = "ID of the API Gateway v2"
  value       = aws_apigatewayv2_api.main.id
}

output "api_gateway_name" {
  description = "Name of the API Gateway v2"
  value       = aws_apigatewayv2_api.main.name
}

output "api_gateway_url" {
  description = "URL of the API Gateway v2"
  value       = aws_apigatewayv2_stage.main.invoke_url
}

output "api_gateway_domain" {
  description = "Domain of the API Gateway v2"
  value       = "${aws_apigatewayv2_api.main.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
}

output "api_gateway_stage_name" {
  description = "Name of the API Gateway v2 stage"
  value       = aws_apigatewayv2_stage.main.name
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway v2"
  value       = aws_apigatewayv2_api.main.execution_arn
}

output "api_gateway_routes" {
  description = "Created API Gateway v2 routes"
  value       = aws_apigatewayv2_route.routes
}

output "api_gateway_integrations" {
  description = "Created API Gateway v2 integrations"
  value       = aws_apigatewayv2_integration.integrations
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group (if logging enabled)"
  value       = var.logging_configuration.enabled ? aws_cloudwatch_log_group.api_gw[0].arn : null
}

data "aws_region" "current" {}
