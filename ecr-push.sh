#!/bin/bash

set -e

echo "Starting ECR deploy test..."

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
echo "Step 2: Building and pushing Docker image..."
TIMESTAMP_1=$(date +%s)
docker build --build-arg CACHE_BUST=$TIMESTAMP_1 -f Dockerfile.test -t "$REPO_NAME:latest" .

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

echo "Image pushed successfully"

# Step 3: Force new deployment and get task ARN
echo ""
echo "Step 3: Forcing new deployment..."
docker exec localstack-main awslocal ecs update-service \
    --region ap-southeast-1 \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --force-new-deployment > /dev/null

# Wait for service to stabilize
echo "Waiting for service to stabilize..."
sleep 15

# Get Task ARN (only running tasks)
TASK_ARN_1=$(docker exec localstack-main awslocal ecs list-tasks --region ap-southeast-1 --cluster "$CLUSTER_NAME" --service-name "$SERVICE_NAME" --desired-status RUNNING --query 'taskArns[0]' --output text)
echo "Task ARN: $TASK_ARN_1"

# Check task status
echo ""
echo "Checking task status..."
TASK_STATUS=$(docker exec localstack-main awslocal ecs describe-tasks --region ap-southeast-1 --cluster "$CLUSTER_NAME" --tasks "$TASK_ARN_1" --query 'tasks[0].lastStatus' --output text)
DESIRED_STATUS=$(docker exec localstack-main awslocal ecs describe-tasks --region ap-southeast-1 --cluster "$CLUSTER_NAME" --tasks "$TASK_ARN_1" --query 'tasks[0].desiredStatus' --output text)
echo "Last Status: $TASK_STATUS"
echo "Desired Status: $DESIRED_STATUS"