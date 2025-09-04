#!/bin/bash

# Script to set up Terraform remote state backend
# This creates S3 bucket and DynamoDB table for state locking

set -e

AWS_REGION=${1:-us-east-1}
BUCKET_NAME="your-org-terraform-state-$(date +%s)"
DYNAMODB_TABLE="terraform-state-lock"

echo "🏗️  Setting up Terraform remote state backend..."
echo "Region: $AWS_REGION"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"

# Create S3 bucket for state
echo "📦 Creating S3 bucket for Terraform state..."
aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION"

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Block public access
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table for state locking
echo "🔒 Creating DynamoDB table for state locking..."
aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region "$AWS_REGION"

echo "✅ Backend setup complete!"
echo ""
echo "Update your terraform.tf files with:"
echo "backend \"s3\" {"
echo "  bucket         = \"$BUCKET_NAME\""
echo "  key            = \"<project>/<environment>/terraform.tfstate\""
echo "  region         = \"$AWS_REGION\""
echo "  dynamodb_table = \"$DYNAMODB_TABLE\""
echo "  encrypt        = true"
echo "}"
