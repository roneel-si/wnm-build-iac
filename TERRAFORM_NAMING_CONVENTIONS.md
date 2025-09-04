# 📋 Terraform Naming Conventions & File Organization

This document outlines the naming conventions and file organization standards for our Infrastructure as Code (IAC) repository.

## 🗂️ File Organization Patterns

### **Project-Level Structure:**
```
projects/{project_name}/
├── 01-providers.tf     # Terraform, providers, backend config
├── 02-locals.tf        # Local values, computed values, tags
├── 03-storage.tf       # S3 buckets, EFS, storage resources
├── 04-compute.tf       # Lambda, EC2, ECS, compute resources
├── 05-networking.tf    # VPC, API Gateway, CloudFront, ALB
├── 06-cicd.tf         # CodePipeline, CodeBuild, deployment
├── 07-monitoring.tf    # CloudWatch, alarms, observability
├── 08-security.tf      # IAM roles, security groups, WAF
├── 09-data.tf         # Data sources and external references
├── variables.tf        # Input variables (always this name)
├── outputs.tf          # Output values (always this name)
└── environments/       # Environment-specific configurations
    ├── dev/
    │   └── terraform.tfvars
    ├── staging/
    │   └── terraform.tfvars
    └── prod/
        └── terraform.tfvars
```

### **Module-Level Structure:**
```
modules/{module_name}/
├── main.tf            # Primary resources
├── variables.tf       # Input variables
├── outputs.tf         # Output values
├── locals.tf          # Local computations (if complex)
├── data.tf           # Data sources (if many)
└── README.md         # Module documentation
```

## 📝 Naming Conventions

### **1. File Names:**
- Use **lowercase** with **dashes**
- Use **numbers for ordering** when logical sequence matters
- Use **descriptive names** that indicate purpose

```bash
✅ Good:
01-providers.tf
03-storage.tf  
lambda-functions.tf
api-gateway.tf

❌ Bad:
Providers.tf
storage_stuff.tf
lambda.tf
ag.tf
```

### **2. Resource Names:**
- Use **descriptive, consistent names**
- Include **environment** when applicable
- Use **underscores** in Terraform resource names
- Use **dashes** in actual AWS resource names

```hcl
# ✅ Good
resource "aws_s3_bucket" "website" {
  bucket = "${var.project_name}-${var.environment}-frontend"
}

resource "aws_lambda_function" "api_handler" {
  function_name = "${var.project_name}-${var.environment}-api"
}

# ❌ Bad  
resource "aws_s3_bucket" "bucket1" {
  bucket = "mybucket"
}

resource "aws_lambda_function" "func" {
  function_name = "lambda1"
}
```

### **3. Variable Names:**
- Use **snake_case**
- Be **descriptive and specific**
- Group related variables together

```hcl
# ✅ Good
variable "lambda_memory_size" {
  description = "Memory allocation for Lambda function in MB"
  type        = number
  default     = 128
}

variable "api_gateway_throttle_limit" {
  description = "API Gateway throttling limit per second"
  type        = number
  default     = 1000
}

# ❌ Bad
variable "memory" {
  type    = number
  default = 128
}

variable "limit" {
  type = number
}
```

### **4. Module Names:**
- Use **descriptive, service-focused names**
- Avoid abbreviations unless universally known

```hcl
# ✅ Good
module "api_gateway" {
  source = "../../modules/api-gateway"
}

module "lambda_functions" {
  source = "../../modules/lambda"
}

# ❌ Bad
module "ag" {
  source = "../../modules/apigw"
}

module "funcs" {
  source = "../../modules/lambda"
}
```

### **5. Output Names:**
- Be **specific about what's being output**
- Include **resource type** if helpful

```hcl
# ✅ Good
output "api_gateway_url" {
  description = "URL of the API Gateway endpoint"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "lambda_function_arn" {
  description = "ARN of the API Lambda function"
  value       = aws_lambda_function.api.arn
}

# ❌ Bad
output "url" {
  value = aws_api_gateway_stage.main.invoke_url
}

output "arn" {
  value = aws_lambda_function.api.arn
}
```

## 🏷️ Tagging Conventions

### **Standard Tags (Always Include):**
```hcl
locals {
  common_tags = {
    Project     = "sportziq"           # Project identifier
    Environment = var.environment      # dev/staging/prod
    ManagedBy   = "Terraform"         # How it's managed
    Owner       = "DevOps"            # Responsible team
    CostCenter  = "engineering"       # For cost allocation
  }
}
```

### **Resource-Specific Tags:**
```hcl
# Add specific tags per resource type
resource "aws_s3_bucket" "website" {
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-frontend"
    Type = "Website"
    BackupRequired = "true"
  })
}
```

## 📁 Environment Organization

### **Environment-Specific Values:**
```hcl
# environments/dev/terraform.tfvars
environment = "dev"
lambda_memory_size = 128
api_gateway_throttle_limit = 100

# environments/prod/terraform.tfvars  
environment = "prod"
lambda_memory_size = 512
api_gateway_throttle_limit = 10000
```

## 🎯 File Content Guidelines

### **01-providers.tf:**
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers { ... }
  backend "s3" { ... }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}
```

### **02-locals.tf:**
```hcl
locals {
  project_name = "sportziq"
  
  common_tags = merge(var.common_tags, {
    Project     = local.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
  
  # Environment-specific computations
  is_production = var.environment == "prod"
  backup_retention = local.is_production ? 90 : 7
}
```

### **03-storage.tf:**
```hcl
# =============================================================================
# STORAGE - S3, EFS, and storage-related resources
# =============================================================================

module "s3" {
  source = "../../modules/s3"
  # ... configuration
}
```

## 🔍 Comments & Documentation

### **File Headers:**
```hcl
# =============================================================================
# COMPUTE - Lambda functions and compute resources
# 
# This file contains all compute-related infrastructure including:
# - Lambda functions for API and background processing
# - Auto-scaling configurations
# - Performance monitoring setup
# =============================================================================
```

### **Module Blocks:**
```hcl
# Lambda functions for SportzIQ API
module "lambda" {
  source = "../../modules/lambda"

  project_name = local.project_name
  environment  = var.environment

  # Serverless configuration - no VPC for better cold start performance
  # vpc_id = module.vpc.vpc_id  # Commented out for serverless architecture

  tags = local.common_tags
}
```

## ✅ Benefits of This Organization

### **For Developers:**
- ✅ **Easy navigation** - find resources quickly
- ✅ **Clear responsibility** - each file has a specific purpose
- ✅ **Better diffs** - changes are isolated to relevant files
- ✅ **Parallel work** - team members can work on different files

### **For Operations:**
- ✅ **Faster troubleshooting** - networking issues → check 05-networking.tf
- ✅ **Targeted changes** - modify only relevant infrastructure
- ✅ **Better reviews** - focused pull request reviews
- ✅ **Documentation** - self-documenting file structure

### **For Architecture:**
- ✅ **Logical separation** - infrastructure layers are clear
- ✅ **Dependency management** - file order shows dependencies
- ✅ **Scalability** - easy to add new infrastructure types
- ✅ **Consistency** - same pattern across all projects

## 🚀 Migration Strategy

### **From Single main.tf:**
1. Create numbered files (01-07)
2. Move resources to appropriate files
3. Test with `terraform plan`
4. Delete old main.tf when confirmed working

### **File Size Guidelines:**
- **Keep files under 150 lines** when possible
- **Split large modules** into separate files if needed
- **Use comments** to separate logical sections
- **Group related resources** together

This organization makes your infrastructure **professional, maintainable, and scalable**! 🏆
