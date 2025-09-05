# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  count = length([for k, v in var.origins : k if v.origin_access_control_id == "auto"])
  
  name                              = "${var.project_name}-${var.environment}-s3-oac"
  description                       = "OAC for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create a local for S3 OAC ID mapping
locals {
  s3_oac_id = length(aws_cloudfront_origin_access_control.s3_oac) > 0 ? aws_cloudfront_origin_access_control.s3_oac[0].id : ""
  
  # Process origins and replace "auto" OAC with actual ID
  processed_origins = {
    for key, config in var.origins : key => merge(config, {
      origin_id = config.origin_id != "" ? config.origin_id : "${key}-${var.project_name}-${var.environment}"
      origin_access_control_id = config.origin_access_control_id == "auto" ? local.s3_oac_id : config.origin_access_control_id
    })
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  comment             = var.cloudfront_config.comment != "" ? var.cloudfront_config.comment : "${var.project_name} ${var.environment} distribution"
  default_root_object = var.cloudfront_config.default_root_object
  enabled             = var.cloudfront_config.enabled
  is_ipv6_enabled     = var.cloudfront_config.is_ipv6_enabled
  price_class         = var.cloudfront_config.price_class
  web_acl_id          = var.cloudfront_config.web_acl_id

  # Dynamic Origins
  dynamic "origin" {
    for_each = local.processed_origins
    content {
      domain_name              = origin.value.domain_name
      origin_id                = origin.value.origin_id
      origin_path              = origin.value.origin_path
      origin_access_control_id = origin.value.origin_access_control_id != "" ? origin.value.origin_access_control_id : null

      # Custom Origin Config (for API Gateway, etc.)
      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? [origin.value.custom_origin_config] : []
        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = custom_origin_config.value.origin_keepalive_timeout
          origin_read_timeout      = custom_origin_config.value.origin_read_timeout
        }
      }
    }
  }

  # Default Cache Behavior
  default_cache_behavior {
    target_origin_id       = var.cache_behaviors.default_cache_behavior.target_origin_id
    viewer_protocol_policy = var.cache_behaviors.default_cache_behavior.viewer_protocol_policy
    allowed_methods        = var.cache_behaviors.default_cache_behavior.allowed_methods
    cached_methods         = var.cache_behaviors.default_cache_behavior.cached_methods
    compress               = var.cache_behaviors.default_cache_behavior.compress

    forwarded_values {
      query_string            = var.cache_behaviors.default_cache_behavior.forwarded_values.query_string
      query_string_cache_keys = var.cache_behaviors.default_cache_behavior.forwarded_values.query_string_cache_keys
      headers                 = var.cache_behaviors.default_cache_behavior.forwarded_values.headers

      cookies {
        forward           = var.cache_behaviors.default_cache_behavior.forwarded_values.cookies.forward
        whitelisted_names = var.cache_behaviors.default_cache_behavior.forwarded_values.cookies.whitelisted_names
      }
    }

    min_ttl     = var.cache_behaviors.default_cache_behavior.min_ttl
    default_ttl = var.cache_behaviors.default_cache_behavior.default_ttl
    max_ttl     = var.cache_behaviors.default_cache_behavior.max_ttl
  }

  # Dynamic Ordered Cache Behaviors
  dynamic "ordered_cache_behavior" {
    for_each = var.cache_behaviors.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ordered_cache_behavior.value.cached_methods
      compress               = ordered_cache_behavior.value.compress

      forwarded_values {
        query_string            = ordered_cache_behavior.value.forwarded_values.query_string
        query_string_cache_keys = ordered_cache_behavior.value.forwarded_values.query_string_cache_keys
        headers                 = ordered_cache_behavior.value.forwarded_values.headers

        cookies {
          forward           = ordered_cache_behavior.value.forwarded_values.cookies.forward
          whitelisted_names = ordered_cache_behavior.value.forwarded_values.cookies.whitelisted_names
        }
      }

      min_ttl     = ordered_cache_behavior.value.min_ttl
      default_ttl = ordered_cache_behavior.value.default_ttl
      max_ttl     = ordered_cache_behavior.value.max_ttl
    }
  }

  # Dynamic Custom Error Responses
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  # Geographic Restrictions
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction.restriction_type
      locations        = var.geo_restriction.locations
    }
  }

  # SSL/TLS Configuration
  viewer_certificate {
    cloudfront_default_certificate = var.viewer_certificate.cloudfront_default_certificate
    acm_certificate_arn           = var.viewer_certificate.acm_certificate_arn != "" ? var.viewer_certificate.acm_certificate_arn : null
    ssl_support_method            = var.viewer_certificate.ssl_support_method != "" ? var.viewer_certificate.ssl_support_method : null
    minimum_protocol_version      = var.viewer_certificate.minimum_protocol_version
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cloudfront"
  })

  # Ensure distribution is created after origins
  depends_on = [aws_cloudfront_origin_access_control.s3_oac]
}