output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_dns" {
  value = aws_lb.main.dns_name
}
