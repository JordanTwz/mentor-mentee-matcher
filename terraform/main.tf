module "network" {
  source     = "./modules/network"
  aws_region = var.aws_region
  tags       = local.global_tags
  env        = var.env
  app_name   = var.app_name
}

module "alb" {
  source     = "./modules/alb"
  aws_region = var.aws_region
  tags       = local.global_tags
  env        = var.env
  app_name   = var.app_name
  alb_subnets = [
    for key, subnet in local.public_subnets : subnet.id
    if contains(["a", "b"], key)
  ]
  vpc_id = local.vpc_id
}
