output "ecs_cluster_name" {
  value = aws_ecs_cluster.app.name
}

output "ecs_tg_arn" {
  value = aws_lb_target_group.default.arn
}
