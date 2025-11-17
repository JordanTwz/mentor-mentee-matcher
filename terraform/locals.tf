locals {
  global_tags = {
    Environment   = var.env
    ManagedBy     = "terraform"
    Application   = var.app_name
    Owner         = var.owner
    ProvisionedBy = "ci-cd"
  }

  public_subnets = element(concat(module.network_real.*.public_subnets, module.network_mock.*.public_subnets), 0)
}

