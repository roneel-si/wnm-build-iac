variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Generic CloudFront Configuration
variable "cloudfront_config" {
  description = "CloudFront distribution configuration"
  type = object({
    comment             = optional(string, "")
    default_root_object = optional(string, "index.html")
    enabled             = optional(bool, true)
    is_ipv6_enabled     = optional(bool, true)
    price_class         = optional(string, "PriceClass_100")
    web_acl_id          = optional(string, "")
  })
  default = {}
}

# Dynamic Origins Configuration
variable "origins" {
  description = "CloudFront origins configuration"
  type = map(object({
    domain_name = string
    origin_id   = optional(string, "")
    origin_path = optional(string, "")
    
    # S3 Origin Configuration
    origin_access_control_id = optional(string, "")
    
    # Custom Origin Configuration
    custom_origin_config = optional(object({
      http_port                = optional(number, 80)
      https_port               = optional(number, 443)
      origin_protocol_policy   = optional(string, "https-only")
      origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])
      origin_keepalive_timeout = optional(number, 5)
      origin_read_timeout      = optional(number, 30)
    }), null)
  }))
  default = {}
}

# Dynamic Cache Behaviors Configuration  
variable "cache_behaviors" {
  description = "CloudFront cache behaviors configuration"
  type = object({
    default_cache_behavior = object({
      target_origin_id       = string
      viewer_protocol_policy = optional(string, "redirect-to-https")
      allowed_methods        = optional(list(string), ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
      cached_methods         = optional(list(string), ["GET", "HEAD"])
      compress               = optional(bool, true)
      
      forwarded_values = optional(object({
        query_string            = optional(bool, false)
        query_string_cache_keys = optional(list(string), [])
        headers                 = optional(list(string), [])
        cookies = optional(object({
          forward           = optional(string, "none")
          whitelisted_names = optional(list(string), [])
        }), { forward = "none" })
      }), { query_string = false, cookies = { forward = "none" } })
      
      min_ttl     = optional(number, 0)
      default_ttl = optional(number, 3600)
      max_ttl     = optional(number, 86400)
    })
    
    ordered_cache_behaviors = optional(map(object({
      path_pattern           = string
      target_origin_id       = string
      viewer_protocol_policy = optional(string, "redirect-to-https")
      allowed_methods        = optional(list(string), ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
      cached_methods         = optional(list(string), ["GET", "HEAD"])
      compress               = optional(bool, true)
      
      forwarded_values = optional(object({
        query_string            = optional(bool, true)
        query_string_cache_keys = optional(list(string), [])
        headers                 = optional(list(string), [])
        cookies = optional(object({
          forward           = optional(string, "none")
          whitelisted_names = optional(list(string), [])
        }), { forward = "none" })
      }), { query_string = true, cookies = { forward = "none" } })
      
      min_ttl     = optional(number, 0)
      default_ttl = optional(number, 0)
      max_ttl     = optional(number, 0)
    })), {})
  })
}

# Error Pages Configuration
variable "custom_error_responses" {
  description = "Custom error responses for CloudFront"
  type = map(object({
    error_code            = number
    response_code         = optional(number, 200)
    response_page_path    = optional(string, "/index.html")
    error_caching_min_ttl = optional(number, 300)
  }))
  default = {
    "404" = {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  }
}

# Geographic Restrictions
variable "geo_restriction" {
  description = "Geographic restriction configuration"
  type = object({
    restriction_type = optional(string, "none")
    locations        = optional(list(string), [])
  })
  default = {
    restriction_type = "none"
  }
}

# SSL/TLS Configuration
variable "viewer_certificate" {
  description = "SSL/TLS certificate configuration"
  type = object({
    cloudfront_default_certificate = optional(bool, true)
    acm_certificate_arn           = optional(string, "")
    ssl_support_method            = optional(string, "")
    minimum_protocol_version      = optional(string, "TLSv1.2_2021")
  })
  default = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
