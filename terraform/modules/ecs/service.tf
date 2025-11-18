resource "aws_ecs_service" "app-service" {
  name                               = "${var.app_name}-service"
  cluster                            = aws_ecs_cluster.app.id
  task_definition                    = aws_ecs_task_definition.app-service.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  health_check_grace_period_seconds  = 30
  force_new_deployment               = true

  load_balancer {
    target_group_arn = var.tg_arn
    container_name   = var.container_name
    container_port   = var.app_port
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.app_cp.name
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }
}
