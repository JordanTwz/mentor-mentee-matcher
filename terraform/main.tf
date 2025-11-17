module "network_real" {
  source     = "./modules/network"
  aws_region = var.aws_region
  tags       = local.global_tags
  env        = var.env
  app_name   = var.app_name
  count      = var.use_localstack ? 0 : 1
}

module "network_mock" {
  source     = "./modules/network"
  aws_region = var.aws_region
  tags       = local.global_tags
  env        = var.env
  app_name   = var.app_name
  count      = var.use_localstack ? 1 : 0
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
}
