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

    # Plan with use_localstack=true and debug logging
    Write-Host "Running Terraform plan with endpoint validation..."
    $env:TF_LOG = "DEBUG"
    $env:TF_LOG_PATH = "../.logs/terraform-plan.log"
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

    # Validate all endpoints are LocalStack
    Write-Host "Validating Terraform is using LocalStack endpoints..."
    $awsMatches = Select-String -Path "../.logs/terraform-plan.log" -Pattern "amazonaws\.com" | Where-Object { $_.Line -notmatch "xmlns=" }
    if ($awsMatches) {
        Write-Host "ERROR: Terraform is trying to reach real AWS endpoints!" -ForegroundColor Red
        Write-Host "Found AWS API calls:"
        $awsMatches | Select-Object -First 10
        Write-Host ""
        Write-Host "All API calls must go to localhost:4566 (LocalStack)"
        throw "AWS endpoint validation failed"
    }

    $planLog = Get-Content "../.logs/terraform-plan.log" -Raw
    if ($planLog -notmatch "localhost:4566") {
        Write-Host "ERROR: No LocalStack endpoints found in Terraform logs!" -ForegroundColor Red
        Write-Host "Expected to find localhost:4566 in API calls"
        throw "LocalStack endpoint validation failed"
    }

    Write-Host "Endpoint validation passed - all calls going to LocalStack" -ForegroundColor Green

    # Apply with use_localstack=true and debug logging
    Write-Host "Applying Terraform..."
    $env:TF_LOG_PATH = "../.logs/terraform-apply.log"
    terraform apply tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed!"
    }

    # Clean up plan file
    Remove-Item -Path "tfplan" -ErrorAction SilentlyContinue

    Write-Host "Terraform apply completed successfully!"

    # Generate infrastructure diagram with inframap
    Write-Host "Generating infrastructure diagram..."
    if (Get-Command inframap -ErrorAction SilentlyContinue) {
        $imagesDir = Join-Path $PSScriptRoot ".images"
        if (-not (Test-Path $imagesDir)) {
            New-Item -ItemType Directory -Path $imagesDir | Out-Null
        }
        
        # Pull state from LocalStack S3 bucket and pipe to temp file
        Write-Host "Pulling Terraform state from LocalStack S3..."
        $tempState = New-TemporaryFile
        docker exec localstack-main awslocal s3 cp s3://asp-proj-terraform-state/prod/root/terraform.tfstate - | Out-File -FilePath $tempState -Encoding UTF8
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $tempState) -and (Get-Item $tempState).Length -gt 0) {
            $fileSize = (Get-Item $tempState).Length
            Write-Host "State file downloaded successfully ($fileSize bytes)"
            inframap generate $tempState | Out-File -FilePath "$imagesDir\terraform-diagram.dot" -Encoding UTF8
        } else {
            Write-Host "Failed to download state from S3, skipping diagram generation"
        }
        
        if ((Test-Path "$imagesDir\terraform-diagram.dot") -and (Get-Item "$imagesDir\terraform-diagram.dot").Length -gt 0) {
            if (Get-Command dot -ErrorAction SilentlyContinue) {
                dot -Tpng "$imagesDir\terraform-diagram.dot" -o "$imagesDir\terraform-diagram.png"
                Write-Host "Infrastructure diagram saved to .images\terraform-diagram.png"
            } else {
                Write-Host "Graphviz not installed. Diagram saved as DOT file to .images\terraform-diagram.dot"
                Write-Host "Install Graphviz to generate PNG: choco install graphviz"
            }
        }
        
        # Clean up temp state file
        Remove-Item -Path $tempState -ErrorAction SilentlyContinue
    } else {
        Write-Host "inframap not found. Skipping diagram generation."
        Write-Host "Install inframap: choco install inframap"
    }
}
catch {
    Write-Host "Error: $_"
    Set-Location $originalDir
    exit 1
}
finally {
    Set-Location $originalDir
}
