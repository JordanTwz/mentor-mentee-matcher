resource "aws_lb_target_group" "default" {
  name     = "public-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}
