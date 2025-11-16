module "network" {
  source = "./modules/network"
  aws_region = var.aws_region
  tags = local.global_tags
  env = var.env
  app_name = var.app_name
}