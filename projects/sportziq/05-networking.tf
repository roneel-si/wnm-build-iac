# =============================================================================
# NETWORKING - API Gateway, CloudFront, and networking resources  
# =============================================================================

# API Gateway for Lambda functions
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name = local.project_name
  environment  = var.environment

  # SportzIQ API configuration
  api_description = "SportzIQ Trivia API Gateway - handles game APIs"
  
  # SportzIQ API Resources - defines the trivia app structure
  api_resources = {
    # Catch-all proxy for React SPA routing
    proxy = {
      path_part = "{proxy+}"
      methods = {
        any = {
          http_method = "ANY"
          authorization = "NONE"
          integration = {
            type = "AWS_PROXY"
            lambda_function_arn = module.lambda.lambda_functions["api"].arn
          }
          method_responses = {
            "200" = {
              status_code = "200"
              response_parameters = {
                "method.response.header.Access-Control-Allow-Headers" = true
                "method.response.header.Access-Control-Allow-Methods" = true
                "method.response.header.Access-Control-Allow-Origin"  = true
              }
            }
          }
        }
      }
    }
    
    # Root resource for API base path
    root = {
      path_part = ""  # Empty means root resource
      methods = {
        any = {
          http_method = "ANY"
          authorization = "NONE"
          integration = {
            type = "AWS_PROXY"
            lambda_function_arn = module.lambda.lambda_functions["api"].arn
          }
          method_responses = {
            "200" = {
              status_code = "200"
              response_parameters = {
                "method.response.header.Access-Control-Allow-Headers" = true
                "method.response.header.Access-Control-Allow-Methods" = true
                "method.response.header.Access-Control-Allow-Origin"  = true
              }
            }
          }
        }
      }
    }
    
    # API resource for structured endpoints
    api = {
      path_part = "api"
      parent_path = ""  # Direct child of root
      methods = {
        # OPTIONS method will be auto-created by CORS configuration
      }
    }
    
    # Generate Quiz endpoint - main trivia quiz generation API
    generate_quiz = {
      path_part = "generate-quiz"
      parent_path = "api"  # Child of /api, making it /api/generate-quiz
      methods = {
        get = {
          http_method = "GET"
          authorization = "NONE"  # Open access, not protected
          integration = {
            type = "AWS_PROXY"
            lambda_function_arn = module.lambda.lambda_functions["api"].arn
          }
          method_responses = {
            "200" = {
              status_code = "200"
              response_parameters = {
                "method.response.header.Access-Control-Allow-Headers" = true
                "method.response.header.Access-Control-Allow-Methods" = true
                "method.response.header.Access-Control-Allow-Origin"  = true
                "method.response.header.Content-Type" = false
              }
            }
            "400" = {
              status_code = "400"
              response_parameters = {
                "method.response.header.Access-Control-Allow-Origin" = true
              }
            }
            "500" = {
              status_code = "500"
              response_parameters = {
                "method.response.header.Access-Control-Allow-Origin" = true
              }
            }
          }
        }
      }
    }
  }


  # SportzIQ CORS configuration for web application
  cors_configuration = {
    enabled = true
    allow_origins = ["*"]  # Restrict this in production
    allow_headers = [
      "Content-Type", 
      "X-Amz-Date", 
      "Authorization", 
      "X-Api-Key", 
      "X-Amz-Security-Token",
      "X-Game-Session-Id",      # SportzIQ specific
      "X-Player-Id"             # SportzIQ specific
    ]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_credentials = false
    max_age = 3600
  }

  # Stage configuration for SportzIQ
  stage_configuration = {
    stage_name = var.environment
    deployment_description = "SportzIQ Trivia API deployment for ${var.environment}"
    variables = {
      GAME_VERSION = "v1.0"
      FEATURE_FLAGS = "leaderboard:true,multiplayer:false"
    }
    cache_cluster_enabled = var.environment == "prod" ? true : false
    cache_cluster_size = "0.5"
    # Note: API throttling can be implemented via Usage Plans if needed
  }

  # Logging configuration for SportzIQ
  logging_configuration = {
    enabled = true
    retention_days = var.environment == "prod" ? 30 : 7
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      userAgent      = "$context.identity.userAgent"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      error          = "$context.error.message"
      gameSession    = "$context.requestHeader.X-Game-Session-Id"
      playerId       = "$context.requestHeader.X-Player-Id"
    })
  }

  enable_xray_tracing = var.environment == "prod" ? true : false

  tags = local.common_tags
}

# CloudFront CDN for global distribution
module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name = local.project_name
  environment  = var.environment

  # CloudFront Distribution Configuration
  cloudfront_config = {
    comment             = "SportzIQ ${var.environment} - Trivia Game CDN"
    default_root_object = "index.html"
    enabled             = true
    is_ipv6_enabled     = true
    price_class         = var.environment == "prod" ? "PriceClass_All" : "PriceClass_100"
  }

  # Dynamic Origins for SportzIQ
  origins = {
    s3_website = {
      domain_name              = module.s3.website_bucket_domain_name
      origin_access_control_id = "auto"  # Auto-create OAC for S3
    }
    api_gateway = {
      domain_name = module.api_gateway.api_gateway_domain
      origin_path = "/${var.environment}"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # SportzIQ-specific Cache Behaviors
  cache_behaviors = {
    default_cache_behavior = {
      target_origin_id       = "s3_website-${local.project_name}-${var.environment}"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      compress               = true
      
      forwarded_values = {
        query_string = false
        headers      = []
        cookies = {
          forward = "none"
        }
      }
      
      min_ttl     = 0
      default_ttl = 3600    # 1 hour for static assets
      max_ttl     = 86400   # 1 day
    }

    ordered_cache_behaviors = {
      api_routes = {
        path_pattern           = "/api/*"
        target_origin_id       = "api_gateway-${local.project_name}-${var.environment}"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods         = ["GET", "HEAD", "OPTIONS"]
        compress               = true
        
        forwarded_values = {
          query_string = true
          headers      = ["Authorization", "Content-Type", "Accept", "X-Game-Session-Id", "X-Player-Id"]
          cookies = {
            forward = "none"
          }
        }
        
        min_ttl     = 0
        default_ttl = 0  # No caching for API calls
        max_ttl     = 0
      }

      game_assets = {
        path_pattern           = "/static/games/*"
        target_origin_id       = "s3_website-${local.project_name}-${var.environment}"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["GET", "HEAD"]
        cached_methods         = ["GET", "HEAD"]
        compress               = true
        
        forwarded_values = {
          query_string = false
          headers      = []
          cookies = {
            forward = "none"
          }
        }
        
        min_ttl     = 86400   # 1 day
        default_ttl = 604800  # 1 week for game assets
        max_ttl     = 31536000 # 1 year
      }
    }
  }

  # SportzIQ Custom Error Pages
  custom_error_responses = {
    "404" = {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"  # SPA routing
    }
    "403" = {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    }
  }

  # Geographic Restrictions (none for global trivia game)
  geo_restriction = {
    restriction_type = "none"
    locations        = []
  }

  # SSL Configuration for SportzIQ
  viewer_certificate = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = local.common_tags
}
