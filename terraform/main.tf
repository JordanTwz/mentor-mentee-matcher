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
  app_port   = var.app_port
  alb_subnets = [
    for key, subnet in local.public_subnets : subnet.id
    if contains(["a", "b"], key)
  ]
  vpc_id = local.vpc_id

  is_localstack = var.use_localstack
  mock_acm_arn  = var.mock_acm_arn
}

module "ecr" {
  source = "./modules/ecr"
  tags   = local.global_tags
}

module "asg" {
  source     = "./modules/asg"
  aws_region = var.aws_region
  tags       = local.global_tags
  env        = var.env
  app_name   = var.app_name
  app_port   = var.app_port
  asg_subnets = [
    for key, subnet in local.public_subnets : subnet.id
    if contains(["c"], key)
  ]
  vpc_id    = local.vpc_id
  alb_sg_id = module.alb.alb_sg_id

  is_localstack           = var.use_localstack
  mock_ecsInstanceRoleARN = var.mock_ecsInstanceRoleARN
}
