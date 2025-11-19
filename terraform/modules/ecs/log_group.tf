resource "aws_cloudwatch_log_group" "app-log" {
  name              = "/ecs/${var.app_name}-service"
  retention_in_days = 1

  tags = merge(
    var.tags,
    {
      Name = "${var.env}-${var.app_name}-log-group"
      Tier = "logs"
    }
  )
}
