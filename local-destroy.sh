#!/bin/bash

echo "Starting LocalStack Terraform destroy..."

# Check if LocalStack is running
if ! docker ps | grep -q localstack-main; then
    echo "Error: LocalStack is not running!"
    echo "Please start LocalStack first with: docker-compose up -d"
    exit 1
else
    echo "LocalStack is running."
fi

# Navigate to terraform directory
cd terraform

# Initialize Terraform with LocalStack backend
echo "Initializing Terraform with LocalStack backend..."
terraform init -backend-config=../localstack.config -reconfigure

if [ $? -ne 0 ]; then
    echo "Terraform init failed!"
    exit 1
fi

# Destroy with use_localstack=true
echo "Running Terraform destroy..."
terraform destroy -var="use_localstack=true" -auto-approve

if [ $? -eq 0 ]; then
    echo "Terraform destroy completed successfully!"
else
    echo "Terraform destroy failed!"
    exit 1
fi

cd ..
