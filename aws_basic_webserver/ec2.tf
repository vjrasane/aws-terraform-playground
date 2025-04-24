locals {
  server_port = 8080
}
resource "aws_security_group" "webserver" {
    name = "webserver-sg"
    ingress {
        from_port = local.server_port
        to_port = local.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "webserver" {
  ami           = "ami-0c1ac8a41498c1a9c"
  instance_type = "t3.micro"

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World!" > index.html
    nohup busybox httpd -f -p ${local.server_port} &
    EOF

  user_data_replace_on_change = true
  vpc_security_group_ids = [aws_security_group.webserver.id]

  tags = {
    Name = "webserver"
  }
}

output "public_ip" {
  value = aws_instance.webserver.public_ip
  description = "value of the public IP address of the webserver instance"
}