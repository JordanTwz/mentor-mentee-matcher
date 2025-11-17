output "vpc_id" {
  value       = element(concat(module.network_real.*.vpc_id, module.network_mock.*.vpc_id), 0)
  description = "The ID of the created VPC (real or mock)."
}

output "rtb_ids" {
  value       = element(concat(module.network_real.*.rtb_ids, module.network_mock.*.rtb_ids), 0)
  description = "Route table IDs (real or mock)."
}

output "public_subnets" {
  value       = element(concat(module.network_real.*.public_subnets, module.network_mock.*.public_subnets), 0)
  description = "Public subnet IDs (real or mock)."
}

output "alb_arn" {
  value       = module.alb.alb_arn
  description = "ARN of ALB"
}

output "alb_dns" {
  value       = module.alb.alb_dns
  description = "DNS of ALB"
}
