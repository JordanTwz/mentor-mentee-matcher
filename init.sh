#!/bin/bash

# Create S3 bucket for Terraform state
awslocal s3 mb s3://asp-proj-terraform-state --region ap-southeast-1

# Enable versioning on the bucket (recommended for state files)
awslocal s3api put-bucket-versioning \
  --bucket asp-proj-terraform-state \
  --versioning-configuration Status=Enabled

echo "LocalStack initialization complete: S3 bucket 'asp-proj-terraform-state' created"
