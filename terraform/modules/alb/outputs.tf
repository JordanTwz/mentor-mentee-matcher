output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_dns" {
  value = aws_lb.main.dns_name
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "alb_tg_arn" {
  value = aws_lb_target_group.default.arn
}

output "alb_listener" {
  value = aws_lb_listener.default
}
