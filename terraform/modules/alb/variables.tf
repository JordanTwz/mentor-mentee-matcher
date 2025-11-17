variable "tags" {
  type = map(string)
}

variable "alb_subnets" {
  type = list(string)
}

variable "aws_region" {
  type = string
}

variable "env" {
  type = string
}

variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "is_localstack" {
  type = bool
}

variable "mock_acm_arn" {
  type = string
}
