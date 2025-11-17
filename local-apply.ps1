$ErrorActionPreference = "Stop"
$env:TF_CLI_ARGS = "-no-color"

Write-Host "Starting LocalStack Terraform deployment..."

# Check if LocalStack is running
$localstackRunning = docker ps | Select-String "localstack-main"

if (-not $localstackRunning) {
    Write-Host "LocalStack is not running. Starting docker-compose..."
    docker-compose up -d
    Write-Host "Waiting for LocalStack to be ready..."
    Start-Sleep -Seconds 10
} else {
    Write-Host "LocalStack is already running."
}

# Fetch ACM certificate ARN from LocalStack
Write-Host "Fetching ACM certificate ARN from LocalStack..."
$certArn = docker exec localstack-main awslocal acm list-certificates --region ap-southeast-1 --query 'CertificateSummaryList[0].CertificateArn' --output text

if ([string]::IsNullOrWhiteSpace($certArn) -or $certArn -eq "None") {
    throw "Failed to fetch ACM certificate ARN! Make sure LocalStack init.sh created the certificate."
}

Write-Host "Certificate ARN: $certArn"

# Fetch ECS Task Execution Role ARN from LocalStack
Write-Host "Fetching ECS Task Execution Role ARN from LocalStack..."
$ecsTaskExecutionRoleArn = docker exec localstack-main awslocal iam get-role --role-name ecsTaskExecutionRole --query 'Role.Arn' --output text

if ([string]::IsNullOrWhiteSpace($ecsTaskExecutionRoleArn) -or $ecsTaskExecutionRoleArn -eq "None") {
    throw "Failed to fetch ECS Task Execution Role ARN! Make sure LocalStack init.sh created the role."
}

Write-Host "ECS Task Execution Role ARN: $ecsTaskExecutionRoleArn"

# Fetch ECS Instance Role ARN from LocalStack
Write-Host "Fetching ECS Instance Role ARN from LocalStack..."
$ecsInstanceRoleArn = docker exec localstack-main awslocal iam get-role --role-name ecsInstanceRole --query 'Role.Arn' --output text

if ([string]::IsNullOrWhiteSpace($ecsInstanceRoleArn) -or $ecsInstanceRoleArn -eq "None") {
    throw "Failed to fetch ECS Instance Role ARN! Make sure LocalStack init.sh created the role."
}

Write-Host "ECS Instance Role ARN: $ecsInstanceRoleArn"

# Save current directory and navigate to terraform directory
$originalDir = Get-Location
try {
    Set-Location (Join-Path $PSScriptRoot "terraform")

    # Initialize Terraform with LocalStack backend
    Write-Host "Initializing Terraform with LocalStack backend..."
    terraform init -backend-config="..\localstack.config" -reconfigure
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed!"
    }

    # Plan with use_localstack=true
    Write-Host "Running Terraform plan..."
    $planArgs = @(
        "-var=use_localstack=true"
        "-var=env=dev"
        "-var=mock_acm_arn=$certArn"
        "-var=mock_ecsTaskExecutionRoleARN=$ecsTaskExecutionRoleArn"
        "-var=mock_ecsInstanceRoleARN=$ecsInstanceRoleArn"
        "-out=tfplan"
    )
    terraform plan @planArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan failed!"
    }

    # Apply with use_localstack=true
    Write-Host "Applying Terraform..."
    terraform apply tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed!"
    }

    Write-Host "Terraform apply completed successfully!"
}
catch {
    Write-Host "Error: $_"
    Set-Location $originalDir
    exit 1
}
finally {
    Set-Location $originalDir
}
