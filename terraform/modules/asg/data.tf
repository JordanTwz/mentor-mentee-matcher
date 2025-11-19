data "aws_prefix_list" "eic" {
  name = "com.amazonaws.${var.aws_region}.ec2-instance-connect"
}
