variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "s3_bucket_domain_name" {
  description = "S3 website bucket domain name"
  type        = string
}

variable "api_gateway_domain" {
  description = "API Gateway domain name"
  type        = string
}

variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "compress" {
  description = "Enable CloudFront compression"
  type        = bool
  default     = true
}

variable "default_root_object" {
  description = "Default root object for S3 origin"
  type        = string
  default     = "index.html"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
