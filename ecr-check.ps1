$ErrorActionPreference = "Stop"

Write-Host "Starting ECR flow test..."

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
Write-Host "Step 2: Building and pushing Docker image (first deployment)..."
docker build -t "${REPO_NAME}:latest" .

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

Write-Host "First image pushed successfully"

# Step 3: Force new deployment and get task ARN
Write-Host ""
Write-Host "Step 3: Forcing new deployment (first)..."
docker exec localstack-main awslocal ecs update-service `
    --region ap-southeast-1 `
    --cluster $CLUSTER_NAME `
    --service $SERVICE_NAME `
    --force-new-deployment | Out-Null

# Wait for service to stabilize
Write-Host "Waiting for service to stabilize..."
Start-Sleep -Seconds 5

# Get first task ARN
$TASK_ARN_1 = docker exec localstack-main awslocal ecs list-tasks --region ap-southeast-1 --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --query 'taskArns[0]' --output text
Write-Host "First task ARN: $TASK_ARN_1"

# Step 4: Build and push Docker image again (with modification)
Write-Host ""
Write-Host "Step 4: Building and pushing Docker image (second deployment)..."
# Add a comment to Dockerfile to change image digest
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
Add-Content -Path Dockerfile -Value "# Test modification $timestamp"

docker build -t "${REPO_NAME}:latest" .

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Second docker build failed!"
    # Restore Dockerfile
    git checkout Dockerfile 2>$null
    if ($LASTEXITCODE -ne 0) {
        $content = Get-Content Dockerfile
        $content[0..($content.Length-2)] | Set-Content Dockerfile
    }
    exit 1
}

docker tag "${REPO_NAME}:latest" "${REPO_URI}:latest"
docker push "${REPO_URI}:latest"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Second docker push failed!"
    # Restore Dockerfile
    git checkout Dockerfile 2>$null
    if ($LASTEXITCODE -ne 0) {
        $content = Get-Content Dockerfile
        $content[0..($content.Length-2)] | Set-Content Dockerfile
    }
    exit 1
}

# Restore Dockerfile
git checkout Dockerfile 2>$null
if ($LASTEXITCODE -ne 0) {
    $content = Get-Content Dockerfile
    $content[0..($content.Length-2)] | Set-Content Dockerfile
}

Write-Host "Second image pushed successfully"

# Step 5: Force new deployment again and get task ARN
Write-Host ""
Write-Host "Step 5: Forcing new deployment (second)..."
docker exec localstack-main awslocal ecs update-service `
    --region ap-southeast-1 `
    --cluster $CLUSTER_NAME `
    --service $SERVICE_NAME `
    --force-new-deployment | Out-Null

# Wait for service to stabilize
Write-Host "Waiting for service to stabilize..."
Start-Sleep -Seconds 5

# Get second task ARN
$TASK_ARN_2 = docker exec localstack-main awslocal ecs list-tasks --region ap-southeast-1 --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --query 'taskArns[0]' --output text
Write-Host "Second task ARN: $TASK_ARN_2"

# Step 6: Compare task ARNs
Write-Host ""
Write-Host "Step 6: Comparing task ARNs..."
Write-Host "First task ARN:  $TASK_ARN_1"
Write-Host "Second task ARN: $TASK_ARN_2"
Write-Host ""

if ($TASK_ARN_1 -ne $TASK_ARN_2) {
    Write-Host "TEST PASSED: Task ARNs are different. ECS service updated successfully."
    exit 0
} else {
    Write-Host "TEST FAILED: Task ARNs are identical. ECS service did not update."
    exit 1
}
