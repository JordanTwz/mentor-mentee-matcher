variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
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
