resource "aws_lb_listener" "default" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.is_localstack ? var.mock_acm_arn : "arn:aws:acm:ap-southeast-1:368339042148:certificate/eb6d11e7-9664-49e9-a277-7780be53688a"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}
