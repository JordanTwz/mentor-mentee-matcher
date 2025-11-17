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

# Create IAM role for ECS Task Execution
awslocal iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

# Attach AWS managed policy for ECS Task Execution
awslocal iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Create IAM role for ECS Instance (EC2 instances in ECS cluster)
awslocal iam create-role \
  --role-name ecsInstanceRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

# Attach AWS managed policy for ECS Instance
awslocal iam attach-role-policy \
  --role-name ecsInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role

# Create instance profile for ECS Instance Role
awslocal iam create-instance-profile \
  --instance-profile-name ecsInstanceRole

# Add role to instance profile
awslocal iam add-role-to-instance-profile \
  --instance-profile-name ecsInstanceRole \
  --role-name ecsInstanceRole

echo "LocalStack initialization complete: S3 bucket 'asp-proj-terraform-state' created and ACM certificate requested"
echo "IAM roles created: ecsTaskExecutionRole and ecsInstanceRole"
