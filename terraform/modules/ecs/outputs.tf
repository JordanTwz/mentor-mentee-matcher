output "ecs_cluster_name" {
  value = aws_ecs_cluster.app.name
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.app.arn
}

output "ecs_service_arn" {
  value = aws_ecs_service.app-service.arn
}
