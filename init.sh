#!/bin/bash

# Create S3 bucket for Terraform state
awslocal s3 mb s3://asp-proj-terraform-state --region ap-southeast-1

# Enable versioning on the bucket (recommended for state files)
awslocal s3api put-bucket-versioning \
  --bucket asp-proj-terraform-state \
  --versioning-configuration Status=Enabled

# Create fake ACM certificate for ALB
awslocal acm request-certificate \
  --domain-name "*.example.com" \
  --validation-method DNS \
  --region ap-southeast-1

echo "LocalStack initialization complete: S3 bucket 'asp-proj-terraform-state' created and ACM certificate requested"
