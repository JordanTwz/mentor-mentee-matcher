resource "aws_ecr_repository" "ecr-backend-repo" {
  name = "mentor-mentee-matcher"

  force_delete = true
  tags         = var.tags
}
