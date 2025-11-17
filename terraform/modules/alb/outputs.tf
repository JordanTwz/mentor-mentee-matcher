output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_dns" {
  value = aws_lb.main.dns_name
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}
