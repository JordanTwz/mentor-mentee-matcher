#!/bin/bash

set -e

echo "Starting ECR flow test..."

# Step 1: Check if ECR repo exists
echo "Step 1: Checking for ECR repository..."
REPO_NAME=$(docker exec localstack-main awslocal ecr describe-repositories --region ap-southeast-1 --query 'repositories[0].repositoryName' --output text 2>/dev/null || echo "None")

if [ -z "$REPO_NAME" ] || [ "$REPO_NAME" = "None" ]; then
    echo "ERROR: No ECR repository found!"
    exit 1
fi

echo "Found ECR repository: $REPO_NAME"

# Get ECR repository URI
REPO_URI=$(docker exec localstack-main awslocal ecr describe-repositories --region ap-southeast-1 --repository-names "$REPO_NAME" --query 'repositories[0].repositoryUri' --output text)
echo "Repository URI: $REPO_URI"

# Get cluster and service names
CLUSTER_NAME=$(docker exec localstack-main awslocal ecs list-clusters --region ap-southeast-1 --query 'clusterArns[0]' --output text | awk -F'/' '{print $NF}')
SERVICE_NAME=$(docker exec localstack-main awslocal ecs list-services --region ap-southeast-1 --cluster "$CLUSTER_NAME" --query 'serviceArns[0]' --output text | awk -F'/' '{print $NF}')

echo "ECS Cluster: $CLUSTER_NAME"
echo "ECS Service: $SERVICE_NAME"

# Step 2: Build and push Docker image (first time)
echo ""
echo "Step 2: Building and pushing Docker image (first deployment)..."
docker build -t "$REPO_NAME:latest" .

if [ $? -ne 0 ]; then
    echo "ERROR: Docker build failed!"
    exit 1
fi

docker tag "$REPO_NAME:latest" "$REPO_URI:latest"
docker push "$REPO_URI:latest"

if [ $? -ne 0 ]; then
    echo "ERROR: Docker push failed!"
    exit 1
fi

echo "First image pushed successfully"

# Step 3: Force new deployment and get task ARN
echo ""
echo "Step 3: Forcing new deployment (first)..."
docker exec localstack-main awslocal ecs update-service \
    --region ap-southeast-1 \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --force-new-deployment > /dev/null

# Wait for service to stabilize
echo "Waiting for service to stabilize..."
sleep 5

# Get first task ARN
TASK_ARN_1=$(docker exec localstack-main awslocal ecs list-tasks --region ap-southeast-1 --cluster "$CLUSTER_NAME" --service-name "$SERVICE_NAME" --query 'taskArns[0]' --output text)
echo "First task ARN: $TASK_ARN_1"

# Step 4: Build and push Docker image again (with modification)
echo ""
echo "Step 4: Building and pushing Docker image (second deployment)..."
# Add a comment to Dockerfile to change image digest
echo "# Test modification $(date +%s)" >> Dockerfile
docker build -t "$REPO_NAME:latest" .

if [ $? -ne 0 ]; then
    echo "ERROR: Second docker build failed!"
    # Restore Dockerfile
    git checkout Dockerfile 2>/dev/null || sed -i '$ d' Dockerfile
    exit 1
fi

docker tag "$REPO_NAME:latest" "$REPO_URI:latest"
docker push "$REPO_URI:latest"

if [ $? -ne 0 ]; then
    echo "ERROR: Second docker push failed!"
    # Restore Dockerfile
    git checkout Dockerfile 2>/dev/null || sed -i '$ d' Dockerfile
    exit 1
fi

# Restore Dockerfile
git checkout Dockerfile 2>/dev/null || sed -i '$ d' Dockerfile

echo "Second image pushed successfully"

# Step 5: Force new deployment again and get task ARN
echo ""
echo "Step 5: Forcing new deployment (second)..."
docker exec localstack-main awslocal ecs update-service \
    --region ap-southeast-1 \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --force-new-deployment > /dev/null

# Wait for service to stabilize
echo "Waiting for service to stabilize..."
sleep 5

# Get second task ARN
TASK_ARN_2=$(docker exec localstack-main awslocal ecs list-tasks --region ap-southeast-1 --cluster "$CLUSTER_NAME" --service-name "$SERVICE_NAME" --query 'taskArns[0]' --output text)
echo "Second task ARN: $TASK_ARN_2"

# Step 6: Compare task ARNs
echo ""
echo "Step 6: Comparing task ARNs..."
echo "First task ARN:  $TASK_ARN_1"
echo "Second task ARN: $TASK_ARN_2"
echo ""

if [ "$TASK_ARN_1" != "$TASK_ARN_2" ]; then
    echo "TEST PASSED: Task ARNs are different. ECS service updated successfully."
    exit 0
else
    echo "TEST FAILED: Task ARNs are identical. ECS service did not update."
    exit 1
fi
