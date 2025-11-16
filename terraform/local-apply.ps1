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

# Save current directory and navigate to terraform directory
$originalDir = Get-Location
try {
    Set-Location $PSScriptRoot

    # Initialize Terraform with LocalStack backend
    Write-Host "Initializing Terraform with LocalStack backend..."
    terraform init -backend-config="..\localstack.config" -reconfigure
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed!"
    }

    # Plan with use_localstack=true
    Write-Host "Running Terraform plan..."
    terraform plan -var="use_localstack=true" -var="env=dev" -out=tfplan
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
