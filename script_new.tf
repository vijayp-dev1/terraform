provider "aws" {
  region = "ap-south-1"
}

data "aws_availability_zones" "available" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "default-for-az"
    values = ["true"]
  }
}

resource "aws_security_group" "test_sg" {
  name_prefix = "test-sg-1"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

  tags = {
    Name = "test-sg"
  }
  vpc_id = data.aws_vpc.default.id
}


resource "aws_instance" "example_instance" {
  ami = "ami-02eb7a4783e7e9317"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "terraform"
  subnet_id = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.test_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "terraform-instance"
  }


user_data = <<-EOF
            #!/bin/bash
            sudo apt-get update -y
            sudo apt install docker.io -y
            docker pull dstar55/docker-hello-world-spring-boot
            docker run -d -p 8080:8080 dstar55/docker-hello-world-spring-boot
            EOF


}


output "public_dns" {
  value = aws_instance.example_instance.public_dns
}

output "java_application_url" {
  value = "http://${aws_instance.example_instance.public_dns}:8080"
}
