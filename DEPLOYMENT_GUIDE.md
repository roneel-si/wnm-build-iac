# 🚀 SportzIQ CI/CD Deployment Guide

This guide will help you set up the complete CI/CD pipeline for your SportzIQ React frontend using AWS CodePipeline.

## 📋 Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (>= 1.0)
3. **GitHub repository** with your React frontend code
4. **GitHub Personal Access Token** with repo permissions

## 🏗️ Architecture Overview

```
Frontend Repo (GitHub) → CodePipeline → CodeBuild → S3 → CloudFront
                                      ↓
API Calls → CloudFront → API Gateway → Lambda
```

## 📦 Setup Instructions

### Step 1: Configure Remote State Backend

**⚠️ Do this first before any Terraform operations!**

```bash
# Navigate to your infrastructure directory
cd /Users/sagarchavan/si/build/wnm-build-iac

# Run the backend setup script
./scripts/setup-backend.sh

# Update terraform configuration with the generated bucket name
# Edit projects/sportziq/main.tf and uncomment the backend block
# Replace "your-terraform-state-bucket" with the actual bucket name
```

### Step 2: Update Configuration Files

#### A. Update GitHub Configuration
Edit the environment-specific tfvars files:

```bash
# For development
vim projects/sportziq/environments/dev/terraform.tfvars

# Update these values:
github_repo_owner = "your-actual-github-username"
github_repo_name  = "your-frontend-repo-name"
```

#### B. Set GitHub OAuth Token
```bash
# Set as environment variable
export TF_VAR_github_oauth_token="your_github_personal_access_token"

# Or add to your shell profile (~/.bashrc, ~/.zshrc)
echo 'export TF_VAR_github_oauth_token="your_token"' >> ~/.zshrc
```

### Step 3: Prepare Your React Repository

#### A. Add buildspec.yml
Copy the `buildspec.yml` from this infrastructure repo to your React repository root:

```bash
cp buildspec.yml /path/to/your/react/repo/buildspec.yml
```

#### B. Update package.json scripts
Ensure your React app has these scripts:
```json
{
  "scripts": {
    "build": "react-scripts build",
    "test": "react-scripts test",
    "lint": "eslint src/"
  }
}
```

#### C. Environment Variables
Your React app can access the API URL via:
```javascript
// In your React components
const API_URL = process.env.REACT_APP_API_URL;
```

### Step 4: Deploy Infrastructure

#### Development Environment
```bash
cd projects/sportziq

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="environments/dev/terraform.tfvars"
```

#### Production Environment
```bash
# First deploy staging for testing
terraform apply -var-file="environments/staging/terraform.tfvars"

# Then production
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## 🔄 How the CI/CD Works

### 1. **GitHub Push Trigger**
- Push to configured branch (`develop` for dev, `main` for prod)
- CodePipeline automatically detects changes

### 2. **Source Stage**
- Downloads source code from GitHub
- Stores in S3 artifacts bucket

### 3. **Build Stage (CodeBuild)**
- Installs Node.js dependencies
- Runs tests and linting
- Builds React app for production
- Optimizes and bundles assets

### 4. **Deploy Stage**
- Syncs build files to S3 bucket
- Sets appropriate cache headers
- Creates CloudFront invalidation for immediate updates

### 5. **Access Your App**
- **Frontend**: `https://your-cloudfront-domain.cloudfront.net`
- **API**: `https://your-cloudfront-domain.cloudfront.net/api/*`

## 📊 Monitoring & Logs

### CloudWatch Logs
- **CodeBuild Logs**: `/aws/codebuild/sportziq-{env}-frontend-build`
- **Lambda Logs**: `/aws/lambda/sportziq-{env}-api`
- **API Gateway Logs**: `/aws/apigateway/sportziq-{env}`

### Pipeline Status
- **AWS Console**: CodePipeline → `sportziq-{env}-frontend-pipeline`
- **Notifications**: Configure SNS for pipeline status updates

## 🛠️ Troubleshooting

### Common Issues

#### 1. **GitHub OAuth Token Issues**
```bash
# Verify token is set
echo $TF_VAR_github_oauth_token

# Check GitHub token permissions
curl -H "Authorization: token $TF_VAR_github_oauth_token" https://api.github.com/user
```

#### 2. **Build Failures**
- Check CodeBuild logs in CloudWatch
- Verify `buildspec.yml` is in repository root
- Ensure all npm dependencies are in `package.json`

#### 3. **S3 Sync Issues**
- CodeBuild role needs S3 permissions
- Check bucket policy allows CodeBuild access

#### 4. **CloudFront Not Updating**
- Invalidation takes 5-15 minutes
- Check invalidation status in CloudFront console

### Useful Commands

```bash
# Check pipeline status
aws codepipeline get-pipeline-state --name sportziq-dev-frontend-pipeline

# Check build logs
aws logs describe-log-streams --log-group-name /aws/codebuild/sportziq-dev-frontend-build

# Manual CloudFront invalidation
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"

# Check S3 sync
aws s3 ls s3://sportziq-dev-frontend-XXXXX --recursive
```

## 🎯 What's Next?

1. **Custom Domain**: Set up Route 53 and SSL certificates
2. **Monitoring**: Add CloudWatch alarms for pipeline failures
3. **Security**: Implement IAM least privilege policies
4. **Testing**: Add integration tests to build process
5. **Rollback**: Implement blue/green deployments

## 📋 Environment Comparison

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| Branch | `develop` | `staging` | `main` |
| Build Cache | Enabled | Enabled | Enabled |
| Tests Required | Yes | Yes | Yes |
| Manual Approval | No | Optional | Recommended |
| Monitoring | Basic | Enhanced | Full |

## 🔐 Security Best Practices

1. **Never commit secrets** - Use environment variables
2. **Use least privilege** - IAM roles have minimal permissions
3. **Enable encryption** - S3, KMS, and transit encryption
4. **Monitor access** - CloudTrail for audit logs
5. **Regular updates** - Keep dependencies current

---

Need help? Check the AWS CodePipeline documentation or reach out to the DevOps team! 🚀
