variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# API Gateway Configuration
variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = ""
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "endpoint_type" {
  description = "API Gateway endpoint type"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["EDGE", "REGIONAL", "PRIVATE"], var.endpoint_type)
    error_message = "Endpoint type must be one of: EDGE, REGIONAL, PRIVATE"
  }
}

# Dynamic API Resources Configuration
variable "api_resources" {
  description = "Configuration for API Gateway resources and methods"
  type = map(object({
    path_part = string
    parent_path = optional(string, "")  # empty means root resource
    methods = map(object({
      http_method     = string
      authorization   = optional(string, "NONE")
      authorizer_id   = optional(string, "")
      request_parameters = optional(map(bool), {})
      integration = object({
        type                    = string  # AWS, AWS_PROXY, HTTP, HTTP_PROXY, MOCK
        integration_http_method = optional(string, "POST")
        uri                     = optional(string, "")
        lambda_function_arn     = optional(string, "")
        request_templates       = optional(map(string), {})
        passthrough_behavior    = optional(string, "WHEN_NO_MATCH")
      })
      method_responses = optional(map(object({
        status_code = string
        response_parameters = optional(map(bool), {})
        response_models = optional(map(string), {})
      })), {})
      integration_responses = optional(map(object({
        status_code = string
        response_parameters = optional(map(string), {})
        response_templates = optional(map(string), {})
      })), {})
    }))
  }))
  default = {
    proxy = {
      path_part = "{proxy+}"
      methods = {
        any = {
          http_method = "ANY"
          integration = {
            type = "AWS_PROXY"
          }
        }
      }
    }
    root = {
      path_part = ""
      methods = {
        any = {
          http_method = "ANY"
          integration = {
            type = "AWS_PROXY"
          }
        }
      }
    }
  }
}

# CORS Configuration
variable "cors_configuration" {
  description = "CORS configuration for API Gateway"
  type = object({
    enabled = optional(bool, true)
    allow_origins = optional(list(string), ["*"])
    allow_headers = optional(list(string), ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"])
    allow_methods = optional(list(string), ["GET", "POST", "PUT", "DELETE", "OPTIONS"])
    allow_credentials = optional(bool, false)
    max_age = optional(number, 86400)
  })
  default = {
    enabled = true
  }
}

# Stage Configuration
variable "stage_configuration" {
  description = "API Gateway stage configuration"
  type = object({
    stage_name = optional(string, "")  # defaults to environment
    deployment_description = optional(string, "")
    variables = optional(map(string), {})
    cache_cluster_enabled = optional(bool, false)
    cache_cluster_size = optional(string, "0.5")
    # Note: Throttling is handled via Usage Plans in API Gateway, not stage-level
  })
  default = {}
}

# Logging Configuration  
variable "logging_configuration" {
  description = "API Gateway access logging configuration"
  type = object({
    enabled = optional(bool, true)
    format = optional(string, "")  # JSON format if empty
    retention_days = optional(number, 14)
  })
  default = {
    enabled = true
  }
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
