resource "aws_autoscaling_group" "app" {
  name_prefix               = "${var.env}-${var.app_name}-asg-"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  vpc_zone_identifier = var.asg_subnets
}
