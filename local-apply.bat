@echo off
setlocal EnableDelayedExpansion

REM Disable ANSI color codes
set NO_COLOR=1
set TF_CLI_ARGS=-no-color

echo Starting LocalStack Terraform deployment...

REM Check if LocalStack is running
docker ps | findstr "localstack-main" >nul 2>&1
if %errorlevel% neq 0 (
    echo LocalStack is not running. Starting docker-compose...
    docker-compose up -d
    echo Waiting for LocalStack to be ready...
    timeout /t 10 /nobreak >nul 2>&1
) else (
    echo LocalStack is already running.
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

REM Plan with use_localstack=true
echo Running Terraform plan...
terraform plan -var="use_localstack=true" -var="env=dev" -out=tfplan

if %errorlevel% neq 0 (
    echo Terraform plan failed!
    cd ..
    exit /b 1
)

REM Apply with use_localstack=true
echo Applying Terraform...
terraform apply tfplan

if %errorlevel% equ 0 (
    echo Terraform apply completed successfully!
) else (
    echo Terraform apply failed!
    cd ..
    exit /b 1
)

cd ..
