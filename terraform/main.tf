module "network_real" {
  source     = "./modules/network"
  aws_region = var.aws_region
  tags       = local.global_tags
  env        = var.env
  app_name   = var.app_name
  count      = var.use_localstack ? 0 : 1

  providers = {
    aws       = aws
    aws.local = aws
  }
}

module "network_mock" {
  source     = "./modules/network"
  aws_region = var.aws_region
  tags       = local.global_tags
  env        = var.env
  app_name   = var.app_name
  count      = var.use_localstack ? 1 : 0

  providers = {
    aws       = aws.local
    aws.local = aws.local
  }
}