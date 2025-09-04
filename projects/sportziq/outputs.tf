# output "vpc_id" {
#   description = "ID of the VPC"
#   value       = module.vpc.vpc_id
# }

# CloudFront outputs (disabled for LocalStack Community)
# output "cloudfront_distribution_domain" {
#   description = "CloudFront distribution domain name"
#   value       = module.cloudfront.cloudfront_distribution_domain
# }

# output "cloudfront_distribution_id" {
#   description = "CloudFront distribution ID"
#   value       = module.cloudfront.cloudfront_distribution_id
# }

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = module.api_gateway.api_gateway_url
}

output "s3_website_bucket" {
  description = "S3 website bucket name"
  value       = module.s3.website_bucket_name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.lambda_function_name
}
