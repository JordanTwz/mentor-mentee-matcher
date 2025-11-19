resource "aws_lb_target_group" "default" {
  name_prefix = "public-tg-"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = 10

  health_check {
    enabled             = true
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
    port                = "traffic-port"
    timeout             = 5
    path                = "/health"
  }

  lifecycle {
    create_before_destroy = true
  }
}
