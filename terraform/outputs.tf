output "vpc_id" {
  value = element(concat(module.network_real.*.vpc_id, module.network_mock.*.vpc_id), 0)
  description = "The ID of the created VPC (real or mock)."
}

output "rtb_ids" {
  value = element(concat(module.network_real.*.rtb_ids, module.network_mock.*.rtb_ids), 0)
  description = "Route table IDs (real or mock)."
}

output "public_subnet_ids" {
  value = element(concat(module.network_real.*.public_subnet_ids, module.network_mock.*.public_subnet_ids), 0)
  description = "Public subnet IDs (real or mock)."
}