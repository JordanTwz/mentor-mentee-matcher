output "asg_sg_id" {
  value = aws_security_group.asg_sg.id
}

output "asg_arn" {
  value = aws_autoscaling_group.app.arn
}
