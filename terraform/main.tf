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
  vpc_id           = local.vpc_id
  alb_sg_id        = module.alb.alb_sg_id
  aws_az           = var.aws_az
  ecs_cluster_name = local.ecs_cluster_name

  is_localstack = var.use_localstack
}

module "ecs" {
  source         = "./modules/ecs"
  aws_region     = var.aws_region
  tags           = local.global_tags
  env            = var.env
  app_name       = var.app_name
  app_port       = var.app_port
  vpc_id         = local.vpc_id
  aws_az         = var.aws_az
  asg_arn        = local.aws_asg_arn
  repository_url = local.repository_url
  tg_arn         = local.aws_lb_tg_arn
  alb_sg_id      = local.alb_sg_id
  task_subnets = [
    for key, subnet in local.public_subnets : subnet.id
    if contains(["c"], key)
  ]
  listener = local.listener

  is_localstack                = var.use_localstack
  mock_ecsTaskExecutionRoleARN = var.mock_ecsTaskExecutionRoleARN
}
