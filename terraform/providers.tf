provider "aws" {
    region = var.aws_region

    // When using LocalStack, avoid real credential validation and supply mock creds so Terraform won't attempt SSO/STS.
    skip_credentials_validation = var.use_localstack
    skip_metadata_api_check = var.use_localstack
    skip_requesting_account_id = var.use_localstack

    // these will be overridden by the env vars in the CI/CD pipeline
    access_key = var.use_localstack ? "mock" : null
    secret_key = var.use_localstack ? "mock" : null
}

provider "aws" {
    alias = "local"
    region = var.aws_region
    access_key = "mock"
    secret_key = "mock"

    // When using LocalStack, avoid real credential validation and supply mock creds so Terraform won't attempt SSO/STS.
    skip_credentials_validation = var.use_localstack
    skip_metadata_api_check = var.use_localstack
    skip_requesting_account_id = var.use_localstack

    endpoints {
        ec2 = "http://localhost:4566"
        ecs = "http://localhost:4566"
        ecr = "http://localhost:4566"
        iam = "http://localhost:4566"
        cloudwatch = "http://localhost:4566"
        sts = "http://localhost:4566"
        s3 = "http://localhost:4566"
    }
}