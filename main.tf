# TF-UPGRADE-TODO: Block type was not recognized, so this block and its contents were not automatically upgraded.
provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "instance" {
  name = "webserver-instance"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p 8080 &
            EOF

  tags = { 
    Name = "WebServer"
  }
}

