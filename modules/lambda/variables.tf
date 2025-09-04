variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC (optional for serverless architecture)"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets (optional for serverless architecture)"
  type        = list(string)
  default     = []
}

variable "lambda_sg_id" {
  description = "ID of the Lambda security group (optional for serverless architecture)"
  type        = string
  default     = ""
}

variable "lambda_functions" {
  description = "Configuration for Lambda functions"
  type = map(object({
    handler                = string
    runtime                = optional(string, "python3.9")
    timeout                = optional(number, 30)
    memory_size            = optional(number, 128)
    zip_file               = optional(string, "")
    s3_bucket              = optional(string, "")
    s3_key                 = optional(string, "")
    environment_variables  = optional(map(string), {})
  }))
  default = {
    api = {
      handler = "lambda_function.lambda_handler"
      timeout = 30
    }
    background = {
      handler = "lambda_function.lambda_handler"
      timeout = 300
    }
  }
}

variable "lambda_iam_policies" {
  description = "Custom IAM policies for Lambda functions"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch logs retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
