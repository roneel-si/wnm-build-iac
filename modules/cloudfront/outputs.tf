output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_domain" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "cloudfront_distribution_status" {
  description = "Current status of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.status
}

output "cloudfront_origin_access_control_id" {
  description = "ID of the Origin Access Control (if created)"
  value       = length(aws_cloudfront_origin_access_control.s3_oac) > 0 ? aws_cloudfront_origin_access_control.s3_oac[0].id : null
}
