resource "aws_ecs_task_definition" "app-service" {
  family                   = "${var.app_name}-task"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "bridge"
  execution_role_arn       = var.is_localstack ? var.mock_ecsTaskExecutionRoleARN : "arn:aws:iam::368339042148:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name              = "${var.container_name}",
      image             = "${var.repository_url}:latest"
      memoryReservation = 256
      essential         = true
      linuxParameters = {
        initProcessEnabled = true
      }

      portMappings = [{
        containerPort = var.app_port
        hostPort      = 0
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${aws_cloudwatch_log_group.app-log.name}"
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
