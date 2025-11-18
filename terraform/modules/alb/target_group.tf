resource "aws_lb_target_group" "default" {
  name     = "public-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  deregistration_delay = 10

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [aws_lb_listener.default]
  }
}
