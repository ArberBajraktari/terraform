terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
# Here we input the access_key, secret_key and token from the AWS account
# This makes it possible for terraform to connect to AWS.
provider "aws" {
    region = "us-east-1"
    access_key = "ASIAVBO7E476O54MNMO4"
    secret_key = "qMCdDCu5/JiGBXtQ0cgnGU29YU8Xuky3A42pAQas"
    #session_
    token = "FwoGZXIvYXdzEDIaDNx2smtDM75OYpUqcSLBARr+pe5uXxXJcG3Hqk0rxZZHIq8H71BHCydI3ydhuRFLMp2PsLMBQmikNnkHs2W78d3hjPSmS0nOVHfkdjJ1q0muzaHHKnOJioIecuMK4A7QIpI9XeYylhrhjuAZq+yxnjOitADz4+zDOHWzc0gv2nVwxm8HMxsIRiJ8Tcd/nOfMru3NQr092zkgJOcLEfr99J/GiwQnmpss40izZIIzPKOZd8ZY/2tS07+v5Pl8DK2dLXCBAH53bRjqWDd+BBgdnFcoi6mpngYyLW+KG01hdH7PGKflv47sIIudluliyLdlOsDVlA50aRq97PKPupTvnKxBdeBMrQ=="
}


# Created my own VPC
# In this case we used the VPC created by us in our AWS account
resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/23"

  tags = {
    Name = "main"
  }
}

#Created an Internet Gateway
# This is needed so that the VPC and subnets have a connection with the outside world
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "gw_main"
  }
}

# Created a custom Route Table
# This route table basically tells to the devices of the VPC that the route they
# ought to follow is 0.0.0.0/0 (so all)
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "allow_all"
  }
}


# Created a subnet
# Here we create a subnet for the VPC we are using above
# That's why it is connected with the id of the VPC and the mask is smaller
resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.0.0/24"

  tags = {
    Name = "subnet_1"
  }
}

# Associated subnet with Route Table
# Next step would be to associate subnet with the route table (0.0.0.0/0)
# We wrote it for VPC but now we have to specify it for the subnets inside the VPC
# as well
resource "aws_route_table_association" "rt_associate" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_table.id
}


# Create Security Group
# Here are the security groups
# Here we define what can income in our instance and what can outgo
# In this case, we allow connection from outside with HTTP and HTTPS
# It also allows everything to go outside
resource "aws_security_group" "security_group" {
  name        = "allow_https/s"
  description = "Allow HTTP/s"
  vpc_id      = aws_vpc.main.id

  #Allow income HTTPS
  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  #Allow income HTTP
  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  #Allow outgoing All
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_https"
  }
}

# Created a Network Interface with an IP in the subnet (the first IP address)
# This helps facilitate network connectivity for instances
# If we had multiple subnets here, we could have used this to
# communicate on 2 separate subnets
resource "aws_network_interface" "nw_interface" {
  subnet_id       = aws_subnet.subnet_1.id
  security_groups = [aws_security_group.security_group.id]
  count = 4

}

# Assigned an Elastic IP for the Instance
# As seen below, since we have 4 instances of our webservice, we need to allocate
# 4 elastiic IPs for the respective instances as well
# This helps us bcs since it is a reserved public IP Add., then we can use one from
# the desired region
resource "aws_eip" "lb" {
  instance   = element(aws_instance.web.*.id, count.index)
  count = 4
  vpc      = true
}

# Here we found the ami that we wanna use for the instances EC2 that we want to create
# In this case its ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Here we create the Instance (webserver in this case)
# It takes the ami from above, the instance type (freetier in this case) and assigns the
# security groups (so what is allows and what is not)
# We crate 4 instances here
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "<h1>Hello World</h1>" | sudo tee /var/www/html/index.html
  EOF


  # Creates four identical aws ec2 instances
  count = 4

  # Here is the connection of each instance with the network interface
  network_interface {
    device_index            = 0
    network_interface_id    = aws_network_interface.nw_interface[count.index].id
  }

  tags = {
    Name = "my-machine-${count.index}"
  }
}


#Output the public IP of the instance
output "instance_ip" {
  value = aws_instance.web[*].public_ip
}


#Output the public IP of the instance
output "instance_dns" {
  value = aws_eip.lb[*].public_dns
}
