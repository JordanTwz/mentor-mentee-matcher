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
    Set-Location $PSScriptRoot

    # Initialize Terraform with LocalStack backend
    Write-Host "Initializing Terraform with LocalStack backend..."
    terraform init -backend-config="..\localstack.config" -reconfigure
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed!"
    }

    # Destroy with use_localstack=true
    Write-Host "Running Terraform destroy..."
    terraform destroy -var="use_localstack=true" -var="env=dev" -auto-approve
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform destroy failed!"
    }

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
