resource "aws_lb" "main" {
  name               = "app"
  load_balancer_type = "application"
  security_groups    = []
  subnets            = var.alb_subnets

  tags = merge(
    var.tags,
    {
      Name = "${var.env}-${var.aws_region}-${var.app_name}-public-alb"
      Tier = "public"
    }
  )
}
