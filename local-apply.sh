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
    
    # Generate infrastructure diagram with inframap
    echo "Generating infrastructure diagram..."
    if command -v inframap &> /dev/null; then
        mkdir -p ../.images
        
        # Pull state from LocalStack S3 bucket and pipe to temp file
        echo "Pulling Terraform state from LocalStack S3..."
        TEMP_STATE=$(mktemp)
        docker exec localstack-main awslocal s3 cp s3://asp-proj-terraform-state/prod/root/terraform.tfstate - > "$TEMP_STATE"
        
        if [ $? -eq 0 ] && [ -s "$TEMP_STATE" ]; then
            echo "State file downloaded successfully ($(wc -c < "$TEMP_STATE") bytes)"
            inframap generate "$TEMP_STATE" > ../.images/terraform-diagram.dot
        else
            echo "Failed to download state from S3, skipping diagram generation"
        fi
        
        if [ -f ../.images/terraform-diagram.dot ] && [ -s ../.images/terraform-diagram.dot ]; then
            if command -v dot &> /dev/null; then
                dot -Tpng ../.images/terraform-diagram.dot -o ../.images/terraform-diagram.png
                echo "Infrastructure diagram saved to .images/terraform-diagram.png"
            else
                echo "Graphviz not installed. Diagram saved as DOT file to .images/terraform-diagram.dot"
                echo "Install Graphviz to generate PNG: apt-get install graphviz (or brew install graphviz)"
            fi
        fi
        
        # Clean up temp state file
        rm -f "$TEMP_STATE"
    else
        echo "inframap not found. Skipping diagram generation."
        echo "Install inframap from: https://github.com/cycloidio/inframap/releases"
    fi
else
    echo "Terraform apply failed!"
    exit 1
fi

cd ..
