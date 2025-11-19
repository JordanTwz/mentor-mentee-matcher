resource "aws_security_group" "ecs-task_sg" {
  name        = "ecs-task-sg"
  description = "Allows TLS inbound traffic from port ${var.app_port}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.env}-${var.aws_region}-${var.app_name}-public-ecs-task-sg"
      Tier = "public"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "allow_app_port" {
  security_group_id            = aws_security_group.ecs-task_sg.id
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.alb_sg_id
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.ecs-task_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
