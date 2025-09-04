variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "lambda_sg_id" {
  description = "ID of the Lambda security group"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "lambda_handler" {
  description = "Lambda handler for API function"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "background_lambda_handler" {
  description = "Lambda handler for background function"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "background_lambda_timeout" {
  description = "Background Lambda timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 128
}

variable "lambda_zip_file" {
  description = "Path to Lambda ZIP file"
  type        = string
  default     = ""
}

variable "background_lambda_zip_file" {
  description = "Path to background Lambda ZIP file"
  type        = string
  default     = ""
}

variable "lambda_s3_bucket" {
  description = "S3 bucket containing Lambda code"
  type        = string
  default     = ""
}

variable "lambda_s3_key" {
  description = "S3 key for Lambda code"
  type        = string
  default     = ""
}

variable "background_lambda_s3_key" {
  description = "S3 key for background Lambda code"
  type        = string
  default     = ""
}

variable "lambda_environment_variables" {
  description = "Environment variables for Lambda functions"
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
