
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allows TLS inbound traffic to port 5000 of service (Flask endpoint)"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.env}-${var.aws_region}-${var.app_name}-public-alb-sg"
      Tier = "public"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
