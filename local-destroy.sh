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

# Create logs directory
mkdir -p ../.logs

# Initialize Terraform with LocalStack backend
echo "Initializing Terraform with LocalStack backend..."
terraform init -backend-config=../localstack.config -reconfigure

if [ $? -ne 0 ]; then
    echo "Terraform init failed!"
    exit 1
fi

# Plan destroy with debug logging
echo "Running Terraform destroy plan with endpoint validation..."
TF_LOG=DEBUG TF_LOG_PATH=../.logs/terraform-destroy-plan.log terraform plan -destroy -var="use_localstack=true" -var="env=dev" -out=destroy.tfplan

if [ $? -ne 0 ]; then
    echo "Terraform destroy plan failed!"
    exit 1
fi

# Validate all endpoints are LocalStack
echo "Validating Terraform is using LocalStack endpoints..."
if grep "amazonaws\.com" ../.logs/terraform-destroy-plan.log | grep -v "xmlns=" | grep -q "amazonaws\.com"; then
    echo "ERROR: Terraform is trying to reach real AWS endpoints!"
    echo "Found AWS API calls:"
    grep "amazonaws\.com" ../.logs/terraform-destroy-plan.log | grep -v "xmlns=" | head -10
    echo ""
    echo "All API calls must go to localhost:4566 (LocalStack)"
    exit 1
fi

if ! grep -q "localhost:4566" ../.logs/terraform-destroy-plan.log; then
    echo "ERROR: No LocalStack endpoints found in Terraform logs!"
    echo "Expected to find localhost:4566 in API calls"
    exit 1
fi

echo "Endpoint validation passed - all calls going to LocalStack"

# Apply destroy plan with debug logging
echo "Applying Terraform destroy..."
TF_LOG=DEBUG TF_LOG_PATH=../.logs/terraform-destroy.log terraform apply destroy.tfplan

if [ $? -ne 0 ]; then
    echo "Terraform destroy failed!"
    exit 1
fi

# Clean up plan file
rm -f destroy.tfplan

echo "Terraform destroy completed successfully!"

cd ..
