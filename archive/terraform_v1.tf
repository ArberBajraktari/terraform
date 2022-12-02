terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
    region = "us-east-1"
    access_key = "ASIA23SCJ7D3APVSLW6T"
    secret_key = "SSsjrgWMqmN08r7Z+gFLV6wv49K7/6Y1cBE5AaF7"
    #session_
    token = "FwoGZXIvYXdzEEkaDEdRu8qMoUpCmoDv+CLBAYVZWta9vfUl0ya4xALJwIwiaAhGrrMj2kQyndIps11oRe7m9MQl0HvE49/xbKLMgSNbFPf9v+L/vzfXkC7Om3cfLp04WgwYXRCPXB0ls/q3BNvRkOulSaEsWA8vXvzRRgXpS3TToN91700FC4lzH5iBA2ztshYPjAvid6aKsZmWnLNfVSJaIoESJOlTgxBIO9fX3EwMUZQ2Q38/nrBCLAlyhBeKrF2GoA0CeEq1uczdcgOQlBrDP08quUBcn1ngjxMojuPcmwYyLYgAQz23ilDUiX8mPiRp4xecEnlDXbkvh2aPxYOgwBnj3TPfMeZrQO01Er6hSw=="
}

#Use the default VPC
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

#Create Security Group
resource "aws_security_group" "security_group" {
  name        = "allow_https/s"
  description = "Allow HTTP/s"
  vpc_id      = "${aws_default_vpc.default.id}"

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

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

###############
#   Instance needs terms to be accepted...
#   Search for diff ami
#   If doesn't work, ask teacher
###############
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

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.security_group.id]

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
output "instance_dns" {
  value = aws_instance.web.public_dns
}