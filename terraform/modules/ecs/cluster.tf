resource "aws_ecs_cluster" "app" {
  name = "app-cluster"

  tags = merge(
    var.tags,
    {
      Name = "${var.env}-${var.app_name}-cluster"
      Tier = "compute"
    }
  )
}
