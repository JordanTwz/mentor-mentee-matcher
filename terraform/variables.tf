variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_az" {
  type        = string
  default     = "ap-southeast-1a"
  description = "Default AZ for single AZ deploy"
}

variable "env" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  default     = "prod"
}

variable "app_name" {
  type        = string
  description = "Application name"
  default     = "asp_proj"
}

variable "owner" {
  type        = string
  description = "Team or person responsible for this infra"
  default     = "e-scholars"
}

variable "app_port" {
  type        = number
  description = "Port app is listening at"
  default     = 5000
}

variable "use_localstack" {
  type        = bool
  description = "Use LocalStack for local dev or actual (DEFAULT IS FALSE)"
  default     = false
}

variable "mock_acm_arn" {
  type        = string
  description = "Mock ACM for LocalStack"
  default     = ""
}

variable "mock_ecsTaskExecutionRoleARN" {
  type        = string
  description = "Mock ARN for ecsTaskExecutionRole in LocalStack"
  default     = ""
}
