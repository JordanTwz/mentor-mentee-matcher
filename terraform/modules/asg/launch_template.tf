resource "aws_launch_template" "app" {
  name          = "${var.env}-${var.app_name}-lt-"
  image_id      = "ami-072b337bfb528c3c1"
  instance_type = "t2.micro"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  # user_data = base64encode(<<-EOF
  #       #!/bin/bash
  #       echo "ECS_CLUSTER=${var.ecs_cluster_name}" >> /etc/ecs/ecs.config
  #       echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
  #       EOF
  # )

  iam_instance_profile {
    name = "ecsInstanceRole"
  }

  vpc_security_group_ids = [aws_security_group.asg_sg.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.env}-${var.app_name}-lt"
      Tier = "compute"
    }
  )
  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name = "${var.env}-${var.app_name}-ec2"
        Tier = "compute"
      }
    )
  }

  key_name = var.is_localstack ? null : "asp_proj"
}
