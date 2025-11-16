variable "tags" {
    type = map(string)
}

variable "vpc_cidr" {
    type = string
    default = "10.0.255.0/24"
}

variable "public_subnets" {
    type = map(string)
    default = {
        "a" = "10.0.255.0/28",
        "b" = "10.0.255.16/28"
    }
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