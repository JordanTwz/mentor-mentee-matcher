locals {
  global_tags = {
    Environment   = var.env
    ManagedBy     = "terraform"
    Application   = var.app_name
    Owner         = var.owner
    ProvisionedBy = "ci-cd"
  }

  public_subnets   = module.network.public_subnets
  vpc_id           = module.network.vpc_id
  aws_lb_tg_arn    = module.alb.alb_tg_arn
  ecs_cluster_name = module.ecs.ecs_cluster_name
  aws_asg_arn      = module.asg.asg_arn
  repository_url   = module.ecr.ecr_repository_url
  alb_sg_id        = module.alb.alb_sg_id
  listener_arn     = module.alb.alb_listener_arn
}

