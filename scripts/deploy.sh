#!/bin/bash

# Deployment script for IAC projects
# Usage: ./scripts/deploy.sh <project> <environment> <action>
# Example: ./scripts/deploy.sh sportziq dev plan

set -e

PROJECT=$1
ENVIRONMENT=$2
ACTION=${3:-plan}

if [ -z "$PROJECT" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <project> <environment> [action]"
    echo "Projects: sportziq, fanxp, wmac"
    echo "Environments: dev, staging, prod"
    echo "Actions: plan, apply, destroy"
    exit 1
fi

PROJECT_DIR="projects/$PROJECT"
ENV_DIR="$PROJECT_DIR/environments/$ENVIRONMENT"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project '$PROJECT' not found"
    exit 1
fi

if [ ! -d "$ENV_DIR" ]; then
    echo "Error: Environment '$ENVIRONMENT' not found for project '$PROJECT'"
    exit 1
fi

echo "🚀 Deploying $PROJECT ($ENVIRONMENT) - Action: $ACTION"
echo "Working directory: $PROJECT_DIR"

cd "$PROJECT_DIR"

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Format code
echo "🎨 Formatting Terraform code..."
terraform fmt -recursive

# Execute the requested action
case $ACTION in
    plan)
        echo "📋 Planning infrastructure changes..."
        terraform plan -var-file="environments/$ENVIRONMENT/terraform.tfvars"
        ;;
    apply)
        echo "🔨 Applying infrastructure changes..."
        terraform apply -var-file="environments/$ENVIRONMENT/terraform.tfvars" -auto-approve
        ;;
    destroy)
        echo "💥 Destroying infrastructure..."
        terraform destroy -var-file="environments/$ENVIRONMENT/terraform.tfvars" -auto-approve
        ;;
    *)
        echo "Error: Unknown action '$ACTION'"
        echo "Available actions: plan, apply, destroy"
        exit 1
        ;;
esac

echo "✨ Operation completed successfully!"
