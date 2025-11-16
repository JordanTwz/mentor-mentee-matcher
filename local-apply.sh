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
terraform plan -var="use_localstack=true" -var="env=dev" -out=tfplan

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
