# WNM Build IAC Repository

Infrastructure as Code (IAC) repository for managing AWS resources across multiple projects using Terraform.

## 🏗️ Project Structure

```
wnm-build-iac/
├── .cursorrules              # Cursor IDE rules and guidelines
├── .gitignore               # Git ignore patterns for Terraform
├── modules/                 # 🔧 Reusable Terraform modules
│   ├── vpc/                 # VPC with public/private subnets
│   ├── security-groups/     # Security groups for different services
│   ├── lambda/              # Lambda functions with IAM roles
│   ├── api-gateway/         # API Gateway with CORS and logging
│   ├── cloudfront/          # CloudFront distribution
│   ├── s3/                  # S3 buckets (website, artifacts, deployments)
│   ├── monitoring/          # CloudWatch alarms and dashboards
│   └── codepipeline/        # CI/CD pipelines
├── projects/                # 📁 Individual project configurations
│   └── sportziq/           # SportzIQ trivia application
│       ├── main.tf         # Main Terraform configuration
│       ├── variables.tf    # Project-specific variables
│       ├── outputs.tf      # Project outputs
│       └── environments/   # 🌍 Environment-specific configs
│           ├── dev/
│           │   └── terraform.tfvars
│           ├── staging/
│           │   └── terraform.tfvars
│           └── prod/
│               └── terraform.tfvars
├── scripts/                # 🛠️ Deployment and utility scripts
│   ├── deploy.sh          # Main deployment script
│   └── setup-backend.sh   # Backend setup utility
├── terraform.tf           # Global Terraform configuration
├── variables.tf           # Global variables
└── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites

-   [Terraform](https://www.terraform.io/downloads.html) >= 1.0
-   [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
-   Bash shell (for deployment scripts)

### 1. Set Up Remote State Backend (One-time setup)

```bash
# Create S3 bucket and DynamoDB table for state management
./scripts/setup-backend.sh us-east-1
```

### 2. Deploy SportzIQ Infrastructure

```bash
# Plan deployment for development environment
./scripts/deploy.sh sportziq dev plan

# Apply changes to development environment
./scripts/deploy.sh sportziq dev apply

# Deploy to staging
./scripts/deploy.sh sportziq staging apply

# Deploy to production
./scripts/deploy.sh sportziq prod apply
```

## 📋 Deployment Commands

### Using the Deploy Script

The `deploy.sh` script simplifies Terraform operations across projects and environments.

**Syntax:**

```bash
./scripts/deploy.sh <project> <environment> <action>
```

**Parameters:**

-   `<project>`: Project name (e.g., `sportziq`)
-   `<environment>`: Environment name (`dev`, `staging`, `prod`)
-   `<action>`: Terraform action (`plan`, `apply`, `destroy`)

**Examples:**

```bash
# Plan changes for SportzIQ development
./scripts/deploy.sh sportziq dev plan

# Apply changes to SportzIQ staging
./scripts/deploy.sh sportziq staging apply

# Destroy SportzIQ development infrastructure
./scripts/deploy.sh sportziq dev destroy
```

### Manual Terraform Commands

If you prefer to run Terraform commands manually:

```bash
# Navigate to project directory
cd projects/sportziq

# Initialize Terraform
terraform init

# Plan with specific environment
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply with specific environment
terraform apply -var-file="environments/dev/terraform.tfvars"

# Destroy infrastructure
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

## 🆕 Adding a New Project

### Step 1: Create Project Structure

```bash
# Create new project directory structure
mkdir -p projects/your-project/{environments/{dev,staging,prod},modules}
```

### Step 2: Create Terraform Configuration Files

Create the following files in `projects/your-project/`:

#### `main.tf`

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  project_name = "your-project"
  common_tags = merge(var.common_tags, {
    Project     = local.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# Add your modules here
module "vpc" {
  source = "../../modules/vpc"

  project_name = local.project_name
  environment  = var.environment

  # VPC configuration variables
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = local.common_tags
}

# Add other modules as needed...
```

#### `variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Add project-specific variables here
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Add more variables as needed...
```

#### `outputs.tf`

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

# Add more outputs as needed...
```

### Step 3: Create Environment-Specific Configurations

Create `terraform.tfvars` files for each environment:

#### `environments/dev/terraform.tfvars`

```hcl
# Development environment configuration
aws_region  = "us-east-1"
environment = "dev"

# VPC Configuration
vpc_cidr                 = "10.0.0.0/16"
availability_zones       = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs     = ["10.0.10.0/24", "10.0.20.0/24"]

# Common tags
common_tags = {
  Environment = "dev"
  Project     = "your-project"
  Owner       = "dev-team"
  CostCenter  = "development"
}
```

#### `environments/staging/terraform.tfvars`

```hcl
# Staging environment configuration
aws_region  = "us-east-1"
environment = "staging"

# Use different CIDR blocks for staging
vpc_cidr                 = "10.1.0.0/16"
availability_zones       = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs     = ["10.1.10.0/24", "10.1.20.0/24"]

# Common tags
common_tags = {
  Environment = "staging"
  Project     = "your-project"
  Owner       = "qa-team"
  CostCenter  = "staging"
}
```

#### `environments/prod/terraform.tfvars`

```hcl
# Production environment configuration
aws_region  = "us-east-1"
environment = "prod"

# Use different CIDR blocks for production with 3 AZs
vpc_cidr                 = "10.2.0.0/16"
availability_zones       = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs      = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs     = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]

# Common tags
common_tags = {
  Environment = "prod"
  Project     = "your-project"
  Owner       = "ops-team"
  CostCenter  = "production"
}
```

### Step 4: Deploy Your New Project

```bash
# Plan the new project
./scripts/deploy.sh your-project dev plan

# Apply the infrastructure
./scripts/deploy.sh your-project dev apply
```

## 🔧 Available Modules

### Core Infrastructure Modules

-   **`vpc`**: VPC with public/private subnets, NAT gateways, and route tables
-   **`security-groups`**: Security groups for ALB, Lambda, RDS, and ElastiCache
-   **`s3`**: S3 buckets for website hosting, CodePipeline artifacts, and Lambda deployments

### Application Modules

-   **`lambda`**: Lambda functions with IAM roles, VPC configuration, and CloudWatch logs
-   **`api-gateway`**: API Gateway with CORS, logging, and Lambda integration
-   **`cloudfront`**: CloudFront distribution for global content delivery

### CI/CD and Monitoring

-   **`codepipeline`**: CI/CD pipelines for React frontend and Lambda functions
-   **`monitoring`**: CloudWatch alarms for API Gateway, Lambda, and request monitoring

## 🛡️ Security Best Practices

-   **Encryption**: All S3 buckets have server-side encryption enabled
-   **Network Security**: Lambda functions run in private subnets
-   **Access Control**: Security groups follow least privilege principle
-   **State Management**: Terraform state is stored in encrypted S3 bucket with DynamoDB locking
-   **Secrets**: Never commit sensitive data; use AWS Secrets Manager or Parameter Store

## 🌍 Environment Management

### Development (`dev`)

-   Relaxed security settings for easier development
-   Single AZ deployment to reduce costs
-   Shorter log retention periods

### Staging (`staging`)

-   Production-like environment for testing
-   Multi-AZ deployment for reliability testing
-   Medium log retention periods

### Production (`prod`)

-   Strict security settings
-   Multi-AZ deployment across 3 availability zones
-   Extended log retention periods
-   Enhanced monitoring and alerting

## 📊 Monitoring and Observability

Each project includes comprehensive monitoring:

-   **CloudWatch Alarms**: API Gateway errors, Lambda errors, request count spikes
-   **X-Ray Tracing**: Distributed tracing for debugging
-   **Access Logs**: API Gateway and CloudFront access logging
-   **Structured Logging**: JSON format for better searchability

## 🤝 Contributing

1. Follow the established naming conventions: `{project}-{environment}-{resource}`
2. Include proper resource tagging
3. Test changes in development environment first
4. Use the deployment scripts for consistency
5. Document any new modules or significant changes

## 📞 Support

For questions or issues:

1. Check the `.cursorrules` file for coding standards
2. Review existing modules for patterns
3. Test in development environment first
4. Use the deployment scripts for consistent deployments

---

**Current Projects:**

-   ✅ **SportzIQ**: Trivia application with React frontend and Lambda backend
