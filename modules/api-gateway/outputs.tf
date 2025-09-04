output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_name" {
  description = "Name of the API Gateway"
  value       = aws_api_gateway_rest_api.main.name
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_gateway_domain" {
  description = "Domain of the API Gateway"
  value       = "${aws_api_gateway_rest_api.main.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
}

output "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.main.stage_name
}

data "aws_region" "current" {}
