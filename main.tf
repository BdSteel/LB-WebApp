# TF-UPGRADE-TODO: Block type was not recognized, so this block and its contents were not automatically upgraded.
#Choose Cloud Provider and region to deploy to
provider "aws" {
  region = "us-east-2"
}

#Create an AWS Security Group allowing HTTP traffic to/from ALL
resource "aws_security_group" "instance" {
  name = "webserver-instance"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Launch config of a web server from a blank Ubuntu image
resource "aws_launch_configuration" "example" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

#ASG for 2-10 nodes
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones = ["us-east-2a", "us-east-2b"]

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "WebServer Node"
    propagate_at_launch = true
  }
}

#Create a web server from a base vanilla ubuntu image
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

#Create a CLB
resource "aws_elb" "LoadBalancer" {
  name = "loadBalancer"
  security_groups = [aws_security_group.elb.id]
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

#Add LB Listeners to listen on 8080, route to instance on 8080
listener {
  lb_port = 8080
  lb_protocol = "http"
  instance_port = 8080
  instance_protocol = "http"
  }

}

resource "aws_security_group" "elb" {
  name = "terraform-elb"

  #Allow all outbound
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow inbound HTTP from anywhere
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
