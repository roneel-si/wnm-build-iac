# Local variables for configuration
locals {
  api_name = var.api_name != "" ? var.api_name : "${var.project_name}-${var.environment}-api"
  api_description = var.api_description != "" ? var.api_description : "API Gateway for ${var.project_name} ${var.environment}"
  stage_name = var.stage_configuration.stage_name != "" ? var.stage_configuration.stage_name : var.environment
  
  # Create resource hierarchy map
  resources_with_parents = {
    for name, resource in var.api_resources : name => merge(resource, {
      parent_resource_id = resource.parent_path == "" ? null : resource.parent_path
    })
  }
  
  # Default log format if not provided
  default_log_format = jsonencode({
    requestId      = "$context.requestId"
    ip             = "$context.identity.sourceIp"
    caller         = "$context.identity.caller"
    user           = "$context.identity.user"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    resourcePath   = "$context.resourcePath"
    status         = "$context.status"
    protocol       = "$context.protocol"
    responseLength = "$context.responseLength"
  })
}

# API Gateway v2 HTTP API
resource "aws_apigatewayv2_api" "main" {
  name          = local.api_name
  description   = local.api_description
  protocol_type = "HTTP"

  # Built-in CORS support in v2
  cors_configuration {
    allow_origins     = var.cors_configuration.allow_origins
    allow_methods     = var.cors_configuration.allow_methods
    allow_headers     = var.cors_configuration.allow_headers
    allow_credentials = var.cors_configuration.allow_credentials
    max_age           = var.cors_configuration.max_age
  }

  tags = var.tags
}

# API Gateway v2 Routes - simpler than v1 resources+methods
locals {
  # Flatten all routes from the configuration
  all_routes = flatten([
    for resource_name, resource in var.api_resources : [
      for method_name, method in resource.methods : {
        key = "${resource_name}-${method_name}"
        route_key = "${method.http_method} ${local.build_full_path[resource_name]}"
        method = method
        resource_name = resource_name
      }
    ]
  ])
  routes_map = { for item in local.all_routes : item.key => item }
  
  # Build full paths for nested resources
  build_full_path = {
    for name, resource in var.api_resources : name => (
      resource.path_part == "" ? "/" : 
      resource.parent_path == "" ? "/${resource.path_part}" :
      "/${var.api_resources[resource.parent_path].path_part}/${resource.path_part}"
    )
  }
}

# API Gateway v2 Routes
resource "aws_apigatewayv2_route" "routes" {
  for_each = local.routes_map

  api_id    = aws_apigatewayv2_api.main.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.integrations[each.key].id}"

  # Authorization (v2 syntax)
  authorization_type = each.value.method.authorization == "NONE" ? "NONE" : each.value.method.authorization
  authorizer_id      = each.value.method.authorizer_id != "" ? each.value.method.authorizer_id : null
}

# API Gateway v2 Integrations
resource "aws_apigatewayv2_integration" "integrations" {
  for_each = local.routes_map

  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = each.value.method.integration.type == "AWS_PROXY" ? "AWS_PROXY" : each.value.method.integration.type
  integration_method = each.value.method.integration.integration_http_method
  
  # Convert function ARN to invoke ARN format for API Gateway integrations
  integration_uri = each.value.method.integration.lambda_function_arn != "" ? (
    each.value.method.integration.type == "AWS_PROXY" ? 
      "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${each.value.method.integration.lambda_function_arn}/invocations" :
      each.value.method.integration.lambda_function_arn
  ) : each.value.method.integration.uri

  # Payload format for Lambda proxy integration
  payload_format_version = each.value.method.integration.type == "AWS_PROXY" ? "2.0" : null
}

# API Gateway v2 Stage (combines deployment and stage from v1)
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = local.stage_name
  description = var.stage_configuration.deployment_description

  # Stage variables
  stage_variables = var.stage_configuration.variables

  # Auto deploy changes
  auto_deploy = true

  # Access logging - only if enabled
  dynamic "access_log_settings" {
    for_each = var.logging_configuration.enabled ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gw[0].arn
      format = var.logging_configuration.format != "" ? var.logging_configuration.format : local.default_log_format
    }
  }

  # Default route settings (throttling, detailed metrics)
  default_route_settings {
    throttling_rate_limit   = 10000
    throttling_burst_limit  = 5000
    detailed_metrics_enabled = var.enable_xray_tracing
  }

  tags = var.tags

  depends_on = [aws_apigatewayv2_route.routes]
}

# CloudWatch Log Group for API Gateway - only if logging enabled
resource "aws_cloudwatch_log_group" "api_gw" {
  count = var.logging_configuration.enabled ? 1 : 0
  
  name              = "/aws/apigateway/${local.api_name}"
  retention_in_days = var.logging_configuration.retention_days

  tags = var.tags
}

# Static Lambda permissions - based on input configuration, not computed values
locals {
  # Flatten Lambda integrations from input variables (static keys)
  lambda_integrations_list = flatten([
    for resource_name, resource in var.api_resources : [
      for method_name, method in resource.methods : {
        key = "${resource_name}-${method_name}"
        method = method
      }
      if method.integration.type == "AWS_PROXY"
    ]
  ])
  
  # Convert to map with static keys
  lambda_integrations = {
    for item in local.lambda_integrations_list : item.key => item.method
  }
}

resource "aws_lambda_permission" "api_gw" {
  for_each = local.lambda_integrations

  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  # Use the function ARN directly (should be passed as lambda function ARN, not invoke ARN)
  function_name = each.value.integration.lambda_function_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Note: API Gateway v2 handles CORS and responses automatically
# No need for separate method responses, CORS methods, or integration responses
# All handled natively by the cors_configuration in aws_apigatewayv2_api
