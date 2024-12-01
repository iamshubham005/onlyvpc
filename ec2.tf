terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.74.0"
    }
  }
}
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"

  tags = {
    Name = "sub1"
  }
}
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.10.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"

  tags = {
    Name = "sub2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "MRT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "MRT"
  }
}

resource "aws_route_table_association" "Public_association1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.MRT.id
}
resource "aws_key_pair" "deployer" {
  key_name   = "id_rsa.pub"
  public_key = file("${path.module}/id_rsa.pub")
}
resource "aws_instance" "my_ec2_instance1" {
  ami           = "ami-0614680123427b75e" # Replace with the desired AMI ID
  instance_type = "t2.micro"
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true # Ensure the EC2 instance gets a public IP
  vpc_security_group_ids      = [aws_security_group.dynamicsg.id]
  tags = {
    Name = "Jenkins-Server"
  }
}
resource "aws_security_group" "dynamicsg" {
  name        = "allow_ssh"
  description = "Security group to allow inbound SSH connections on port 22"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # This allows SSH from any IP (open to the public internet)
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}