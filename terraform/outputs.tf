output "vpc_id" {
  value       = module.network.vpc_id
  description = "The ID of the created VPC (real or mock)."
}

output "rtb_ids" {
  value       = module.network.*.rtb_ids
  description = "Route table IDs (real or mock)."
}

output "public_subnets" {
  value       = module.network.*.public_subnets
  description = "Public subnet (real or mock)."
}

output "alb_arn" {
  value       = module.alb.alb_arn
  description = "ARN of ALB"
}

output "alb_dns" {
  value       = module.alb.alb_dns
  description = "DNS of ALB"
}

output "env" {
  value       = var.use_localstack ? "LocalStack" : "AWS"
  description = "Environment it is running on"
}
