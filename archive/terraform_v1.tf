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
    access_key = "ASIA23SCJ7D3APVSLW6T"
    secret_key = "SSsjrgWMqmN08r7Z+gFLV6wv49K7/6Y1cBE5AaF7"
    #session_
    token = "FwoGZXIvYXdzEEkaDEdRu8qMoUpCmoDv+CLBAYVZWta9vfUl0ya4xALJwIwiaAhGrrMj2kQyndIps11oRe7m9MQl0HvE49/xbKLMgSNbFPf9v+L/vzfXkC7Om3cfLp04WgwYXRCPXB0ls/q3BNvRkOulSaEsWA8vXvzRRgXpS3TToN91700FC4lzH5iBA2ztshYPjAvid6aKsZmWnLNfVSJaIoESJOlTgxBIO9fX3EwMUZQ2Q38/nrBCLAlyhBeKrF2GoA0CeEq1uczdcgOQlBrDP08quUBcn1ngjxMojuPcmwYyLYgAQz23ilDUiX8mPiRp4xecEnlDXbkvh2aPxYOgwBnj3TPfMeZrQO01Er6hSw=="
}

#Use the default VPC
# In this case we used the default VPC that already exists in our AWS account
# We can also create and use other VPC, already created or that we can create here
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# Create Security Group
# Here are the security groups
# Here we define what can income in our instance and what can outgo
# In this case, we allow connection from outside with HTTP and HTTPS
# It also allows everything to go outside
resource "aws_security_group" "security_group" {
  name        = "allow_https/s"
  description = "Allow HTTP/s"
  vpc_id      = "${aws_default_vpc.default.id}"

  # Incoming HTTPS
  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Incoming HTTPS
  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # outgoing all
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
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.security_group.id]


  # This is the user data, basically the command that will be run after the instance is started
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "<h1>Hello World</h1>" | sudo tee /var/www/html/index.html
  EOF

  tags = {
    Name = "HelloWorld"
  }
}

# Here we just output the public dns name of the instance above
output "instance_dns" {
  value = aws_instance.web.public_dns
}