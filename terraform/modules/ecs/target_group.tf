resource "aws_lb_target_group" "default" {
  name     = "public-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  deregistration_delay = 10
}
