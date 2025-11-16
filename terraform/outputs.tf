output "vpc_id" {
  value = module.network.vpc_id
  description = "The ID of the created VPC."
}

output "rtb_ids" {
  value = module.network.rtb_ids
  description = "The IDs of all route tables"
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
  description = "The IDs of all public subnets"
}