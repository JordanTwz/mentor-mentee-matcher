output "asg_sg_id" {
  value = aws_security_group.asg_sg.id
}

output "asg_lb_tg_arn" {
  value = aws_lb_target_group.default.arn
}
