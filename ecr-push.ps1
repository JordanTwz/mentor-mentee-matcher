$ErrorActionPreference = "Stop"

Write-Host "Starting ECR deploy test..."

# Step 1: Check if ECR repo exists
Write-Host "Step 1: Checking for ECR repository..."
$REPO_NAME = docker exec localstack-main awslocal ecr describe-repositories --region ap-southeast-1 --query 'repositories[0].repositoryName' --output text 2>$null
if ([string]::IsNullOrEmpty($REPO_NAME) -or $REPO_NAME -eq "None") {
    Write-Host "ERROR: No ECR repository found!"
    exit 1
}

Write-Host "Found ECR repository: $REPO_NAME"

# Get ECR repository URI
$REPO_URI = docker exec localstack-main awslocal ecr describe-repositories --region ap-southeast-1 --repository-names $REPO_NAME --query 'repositories[0].repositoryUri' --output text
Write-Host "Repository URI: $REPO_URI"

# Get cluster and service names
$CLUSTER_ARN = docker exec localstack-main awslocal ecs list-clusters --region ap-southeast-1 --query 'clusterArns[0]' --output text
$CLUSTER_NAME = $CLUSTER_ARN.Split('/')[-1]
$SERVICE_ARN = docker exec localstack-main awslocal ecs list-services --region ap-southeast-1 --cluster $CLUSTER_NAME --query 'serviceArns[0]' --output text
$SERVICE_NAME = $SERVICE_ARN.Split('/')[-1]

Write-Host "ECS Cluster: $CLUSTER_NAME"
Write-Host "ECS Service: $SERVICE_NAME"

# Step 2: Build and push Docker image (first time)
Write-Host ""
Write-Host "Step 2: Building and pushing Docker image..."
$TIMESTAMP_1 = [int][double]::Parse((Get-Date -UFormat %s))
docker build --build-arg CACHE_BUST=$TIMESTAMP_1 -f Dockerfile.test -t "${REPO_NAME}:latest" .

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed!"
    exit 1
}

docker tag "${REPO_NAME}:latest" "${REPO_URI}:latest"
docker push "${REPO_URI}:latest"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker push failed!"
    exit 1
}

Write-Host "Image pushed successfully"

# Step 3: Force new deployment and get task ARN
Write-Host ""
Write-Host "Step 3: Forcing new deployment..."
docker exec localstack-main awslocal ecs update-service `
    --region ap-southeast-1 `
    --cluster $CLUSTER_NAME `
    --service $SERVICE_NAME `
    --force-new-deployment | Out-Null

# Wait for service to stabilize
Write-Host "Waiting for service to stabilize..."
Start-Sleep -Seconds 15

# Get Task ARN (only running tasks)
$TASK_ARN_1 = docker exec localstack-main awslocal ecs list-tasks --region ap-southeast-1 --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --desired-status RUNNING --query 'taskArns[0]' --output text
Write-Host "Task ARN: $TASK_ARN_1"

# Check task status
Write-Host ""
Write-Host "Checking task status..."
$TASK_STATUS = docker exec localstack-main awslocal ecs describe-tasks --region ap-southeast-1 --cluster $CLUSTER_NAME --tasks $TASK_ARN_1 --query 'tasks[0].lastStatus' --output text
$DESIRED_STATUS = docker exec localstack-main awslocal ecs describe-tasks --region ap-southeast-1 --cluster $CLUSTER_NAME --tasks $TASK_ARN_1 --query 'tasks[0].desiredStatus' --output text
Write-Host "Last Status: $TASK_STATUS"
Write-Host "Desired Status: $DESIRED_STATUS"
