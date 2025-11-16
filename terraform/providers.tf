provider "aws" {
    region = var.aws_region
    access_key = "mock"
    secret_key = "mock"
    // delete when running, these point to mock
    endpoints {
        ec2 = "http://localhost:4566"
        ecs = "http://localhost:4566"
        ecr = "http://localhost:4566"
        iam = "http://localhost:4566"
        cloudwatch = "http://localhost:4566"
        sts = "http://localhost:4566"
    }
}