locals {
  global_tags = {
    Environment   = var.env
    ManagedBy     = "terraform"
    Application   = var.app_name
    Owner         = var.owner
    ProvisionedBy = "ci-cd"
  }

  public_subnets = module.network.public_subnets
}

