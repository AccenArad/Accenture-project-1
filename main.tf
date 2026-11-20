terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "web_vpc" {
  cidr_block = "10.20.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "capstone-project-1-vpc"
  }
}

# -------------------------
# Internet Gateway
# -------------------------
resource "aws_internet_gateway" "web_igw" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    Name = "capstone-project-1-igw"
  }
}

# -------------------------
# Public Subnet
# -------------------------
resource "aws_subnet" "web_subnet" {
  vpc_id = aws_vpc.web_vpc.id
  cidr_block = "10.20.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "capstone-project-1-subnet"
  }
}

# -------------------------
# Route Table
# -------------------------
resource "aws_route_table" "web_route_table" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_igw.id
  }

  tags = {
    Name = "capstone-project-1-route-table"
  }
}

resource "aws_route_table_association" "web_route_association" {
  subnet_id = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.web_route_table.id
}

# -------------------------
# Security Group
# -------------------------
resource "aws_security_group" "web_sg" {
  name = "capstone-project-1-web-sg"
  description = "Allow HTTP traffic"
  vpc_id = aws_vpc.web_vpc.id

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "capstone-project-1-web-sg"
  }
}

# -------------------------
# Amazon Linux 2023 AMI
# -------------------------
data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# -------------------------
# EC2 Web Server
# -------------------------
resource "aws_instance" "web_server" {
  ami = data.aws_ssm_parameter.amazon_linux.value
  instance_type = "t3.micro"
  subnet_id = aws_subnet.web_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd

              systemctl enable httpd
              systemctl start httpd

              cat <<'HTML' > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>Accenture Capstone - Project 1</title>
              </head>
              <body>
                <h1>Accenture Capstone Project 1</h1>
                <h2>Linux EC2 Web Server</h2>
                <p>Deployed using Terraform.</p>
              </body>
              </html>
              HTML
              EOF

  tags = {
    Name = "capstone-project-1-web-server"
  }
}

# -------------------------
# Output
# -------------------------
output "web_server_public_ip" {
  value = aws_instance.web_server.public_ip
}
