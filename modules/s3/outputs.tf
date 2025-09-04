output "website_bucket_name" {
  description = "Name of the S3 website bucket"
  value       = aws_s3_bucket.website.bucket
}

output "website_bucket_domain_name" {
  description = "Domain name of the S3 website bucket"
  value       = aws_s3_bucket.website.bucket_domain_name
}

output "website_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 website bucket"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

output "codepipeline_artifacts_bucket_name" {
  description = "Name of the CodePipeline artifacts bucket"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "lambda_deployments_bucket_name" {
  description = "Name of the Lambda deployments bucket"
  value       = aws_s3_bucket.lambda_deployments.bucket
}
