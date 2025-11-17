#!/bin/bash

echo "Starting LocalStack Terraform deployment..."

# Check if LocalStack is running
if ! docker ps | grep -q localstack-main; then
    echo "LocalStack is not running. Starting docker-compose..."
    docker-compose up -d
    echo "Waiting for LocalStack to be ready..."
    sleep 10
else
    echo "LocalStack is already running."
fi

# Fetch ACM certificate ARN from LocalStack
echo "Fetching ACM certificate ARN from LocalStack..."
CERT_ARN=$(docker exec localstack-main awslocal acm list-certificates --region ap-southeast-1 --query 'CertificateSummaryList[0].CertificateArn' --output text)

if [ -z "$CERT_ARN" ] || [ "$CERT_ARN" = "None" ]; then
    echo "Failed to fetch ACM certificate ARN! Make sure LocalStack init.sh created the certificate."
    exit 1
fi

echo "Certificate ARN: $CERT_ARN"

# Fetch ECS Task Execution Role ARN from LocalStack
echo "Fetching ECS Task Execution Role ARN from LocalStack..."
ECS_TASK_EXECUTION_ROLE_ARN=$(docker exec localstack-main awslocal iam get-role --role-name ecsTaskExecutionRole --query 'Role.Arn' --output text)

if [ -z "$ECS_TASK_EXECUTION_ROLE_ARN" ] || [ "$ECS_TASK_EXECUTION_ROLE_ARN" = "None" ]; then
    echo "Failed to fetch ECS Task Execution Role ARN! Make sure LocalStack init.sh created the role."
    exit 1
fi

echo "ECS Task Execution Role ARN: $ECS_TASK_EXECUTION_ROLE_ARN"

# Fetch ECS Instance Role ARN from LocalStack
echo "Fetching ECS Instance Role ARN from LocalStack..."
ECS_INSTANCE_ROLE_ARN=$(docker exec localstack-main awslocal iam get-role --role-name ecsInstanceRole --query 'Role.Arn' --output text)

if [ -z "$ECS_INSTANCE_ROLE_ARN" ] || [ "$ECS_INSTANCE_ROLE_ARN" = "None" ]; then
    echo "Failed to fetch ECS Instance Role ARN! Make sure LocalStack init.sh created the role."
    exit 1
fi

echo "ECS Instance Role ARN: $ECS_INSTANCE_ROLE_ARN"

# Navigate to terraform directory
cd terraform

# Initialize Terraform with LocalStack backend
echo "Initializing Terraform with LocalStack backend..."
terraform init -backend-config=../localstack.config -reconfigure

if [ $? -ne 0 ]; then
    echo "Terraform init failed!"
    exit 1
fi

# Plan with use_localstack=true
echo "Running Terraform plan..."
terraform plan \
    -var="use_localstack=true" \
    -var="env=dev" \
    -var="mock_acm_arn=$CERT_ARN" \
    -var="mock_ecsTaskExecutionRoleARN=$ECS_TASK_EXECUTION_ROLE_ARN" \
    -var="mock_ecsInstanceRoleARN=$ECS_INSTANCE_ROLE_ARN" \
    -out=tfplan

if [ $? -ne 0 ]; then
    echo "Terraform plan failed!"
    exit 1
fi

# Apply with use_localstack=true
echo "Applying Terraform..."
terraform apply -var="use_localstack=true" -var="env=dev" tfplan

if [ $? -eq 0 ]; then
    echo "Terraform apply completed successfully!"
else
    echo "Terraform apply failed!"
    exit 1
fi

cd ..
