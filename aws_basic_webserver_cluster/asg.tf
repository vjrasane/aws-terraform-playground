
locals {
  server_port = 8080
}
resource "aws_security_group" "webserver" {
  name = "webserver-sg"
  ingress {
    from_port   = local.server_port
    to_port     = local.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_launch_template" "webserver" {
  image_id               = "ami-0c1ac8a41498c1a9c"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.webserver.id]

  user_data = base64encode(
    <<-EOF
    #!/bin/bash
    echo "Hello, World!" > index.html
    nohup busybox httpd -f -p ${local.server_port} &
    EOF
  )
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_autoscaling_group" "webserver" {
  name = "terraform-asg-webserver"
  launch_template {
    id      = aws_launch_template.webserver.id
    version = "$Latest"
  }

  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.asg.arn]
  health_check_type   = "ELB"
  min_size            = 2
  max_size            = 10
  tag {
    key                 = "Name"
    value               = "terraform-asg-webserver"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
