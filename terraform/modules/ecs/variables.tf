variable "tags" {
  type = map(string)
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

variable "app_port" {
  type = number
}

variable "aws_az" {
  type = string
}

variable "asg_arn" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "task_subnets" {
  type = list(string)
}

variable "tg_arn" {
  type = string
}

variable "listener_arn" {
  type = string
}

variable "repository_url" {
  type = string
}

variable "is_localstack" {
  type = bool
}

variable "mock_ecsTaskExecutionRoleARN" {
  type = string
}

variable "container_name" {
  type    = string
  default = "app"
}
