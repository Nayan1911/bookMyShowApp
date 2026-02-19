provider "aws" {

  region = "ap-south-1"

}

# VPC

resource "aws_vpc" "main" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "bookmyshow-vpc"
  }

}

# Subnet

resource "aws_subnet" "main" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-south-1a"

  tags = {
    Name = "bookmyshow-subnet"
  }

}

# Internet Gateway

resource "aws_internet_gateway" "gw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "bookmyshow-igw"
  }

}

# Route Table

resource "aws_route_table" "rt" {

  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.gw.id

  }

  tags = {
    Name = "bookmyshow-rt"
  }

}

# Route Table Association

resource "aws_route_table_association" "a" {

  subnet_id = aws_subnet.main.id

  route_table_id = aws_route_table.rt.id

}

# Security Group

resource "aws_security_group" "sg" {

  name = "bookmyshow-sg"

  vpc_id = aws_vpc.main.id

  ingress {

    from_port = 22

    to_port = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    from_port = 3000

    to_port = 3000

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

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

}

# EC2 Instance

resource "aws_instance" "web" {

  ami = "ami-0f5ee92e2d63afc18"

  instance_type = "t3.small"

  key_name = "bookMyShow_Key_Pair"

  subnet_id = aws_subnet.main.id

  vpc_security_group_ids = [aws_security_group.sg.id]

  associate_public_ip_address = true

  root_block_device {

    volume_size = 30
  }

  user_data = <<-EOF
                #!/bin/bash

                # Update packages
                sudo apt update -y

                # Install Docker
                sudo apt install docker.io -y

                # Start Docker
                sudo systemctl start docker
                sudo systemctl enable docker

                # Give ubuntu user Docker permission
                sudo usermod -aG docker ubuntu

                # Go to home directory
                cd /home/ubuntu

                # Clone your repo
                git clone https://github.com/Nayan1911/bookMyShowApp.git

                cd bookMyShowApp

                # Build Docker image
                sudo docker build -t bookmyshow .

                # Run Docker container
                sudo docker run -d -p 3000:3000 --name bookmyshow-container bookmyshow

                EOF

  tags = {

    Name = "bookmyshow-ec2"
  }

}

