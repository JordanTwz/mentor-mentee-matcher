$ErrorActionPreference = "Stop"
$env:TF_CLI_ARGS = "-no-color"

Write-Host "Starting LocalStack Terraform destroy..."

# Check if LocalStack is running
$localstackRunning = docker ps | Select-String "localstack-main"

if (-not $localstackRunning) {
    Write-Host "Error: LocalStack is not running!"
    Write-Host "Please start LocalStack first with: docker-compose up -d"
    exit 1
} else {
    Write-Host "LocalStack is running."
}

# Save current directory and navigate to terraform directory
$originalDir = Get-Location
try {
    Set-Location (Join-Path $PSScriptRoot "terraform")

    # Create logs directory
    $logsDir = Join-Path $PSScriptRoot ".logs"
    if (-not (Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir | Out-Null
    }

    # Initialize Terraform with LocalStack backend
    Write-Host "Initializing Terraform with LocalStack backend..."
    terraform init -backend-config="..\localstack.config" -reconfigure
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed!"
    }

    # Plan destroy with debug logging
    Write-Host "Running Terraform destroy plan with endpoint validation..."
    $env:TF_LOG = "DEBUG"
    $env:TF_LOG_PATH = "../.logs/terraform-destroy-plan.log"
    terraform plan -destroy -var="use_localstack=true" -var="env=dev" -out=destroy.tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform destroy plan failed!"
    }

    # Validate all endpoints are LocalStack
    Write-Host "Validating Terraform is using LocalStack endpoints..."
    $awsMatches = Select-String -Path "../.logs/terraform-destroy-plan.log" -Pattern "amazonaws\.com" | Where-Object { $_.Line -notmatch "xmlns=" }
    if ($awsMatches) {
        Write-Host "ERROR: Terraform is trying to reach real AWS endpoints!" -ForegroundColor Red
        Write-Host "Found AWS API calls:"
        $awsMatches | Select-Object -First 10
        Write-Host ""
        Write-Host "All API calls must go to localhost:4566 (LocalStack)"
        throw "AWS endpoint validation failed"
    }

    $destroyPlanLog = Get-Content "../.logs/terraform-destroy-plan.log" -Raw
    if ($destroyPlanLog -notmatch "localhost:4566") {
        Write-Host "ERROR: No LocalStack endpoints found in Terraform logs!" -ForegroundColor Red
        Write-Host "Expected to find localhost:4566 in API calls"
        throw "LocalStack endpoint validation failed"
    }

    Write-Host "Endpoint validation passed - all calls going to LocalStack" -ForegroundColor Green

    # Apply destroy plan with debug logging
    Write-Host "Applying Terraform destroy..."
    $env:TF_LOG_PATH = "../.logs/terraform-destroy.log"
    terraform apply destroy.tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform destroy failed!"
    }

    # Clean up plan file
    Remove-Item -Path "destroy.tfplan" -ErrorAction SilentlyContinue

    Write-Host "Terraform destroy completed successfully!"
}
catch {
    Write-Host "Error: $_"
    Set-Location $originalDir
    exit 1
}
finally {
    Set-Location $originalDir
}
