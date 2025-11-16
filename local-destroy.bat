@echo off
setlocal EnableDelayedExpansion

REM Disable ANSI color codes
set NO_COLOR=1
set TF_CLI_ARGS=-no-color

echo Starting LocalStack Terraform destroy...

REM Check if LocalStack is running
docker ps | findstr "localstack-main" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: LocalStack is not running!
    echo Please start LocalStack first with: docker-compose up -d
    exit /b 1
) else (
    echo LocalStack is running.
)

REM Navigate to terraform directory
cd terraform

REM Initialize Terraform with LocalStack backend
echo Initializing Terraform with LocalStack backend...
terraform init -backend-config=..\localstack.config -reconfigure

if %errorlevel% neq 0 (
    echo Terraform init failed!
    cd ..
    exit /b 1
)

REM Destroy with use_localstack=true
echo Running Terraform destroy...
terraform destroy -var="use_localstack=true" -var="env=dev" -auto-approve

if %errorlevel% equ 0 (
    echo Terraform destroy completed successfully!
) else (
    echo Terraform destroy failed!
    cd ..
    exit /b 1
)

cd ..
