resource "aws_ecs_capacity_provider" "app_cp" {
  name = "${var.env}-${var.app_name}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.asg_arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 80
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "app_ccp" {
  cluster_name       = aws_ecs_cluster.app.name
  capacity_providers = [aws_ecs_capacity_provider.app_cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.app_cp.name
    weight            = 1
  }
}
