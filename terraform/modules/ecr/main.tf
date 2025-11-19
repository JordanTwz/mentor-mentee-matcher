resource "aws_ecr_repository" "ecr-backend-repo" {
  name = "mentor-mentee-matcher"

  tags = var.tags
}
