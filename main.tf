# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyVPC"
  }
}

# IGW
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyIGW"
  }
}

# Public Subnets 1 & 2
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1b"

  tags = {
    Name = "PublicSubnet2"
  }
}

# Creating Route Table and Associate Routes
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "MainRouteTable"
  }
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.main_rt.id
}

# Security Group
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
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
    Name = "WebSecurityGroup"
  }
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami             = "ami-05c179eced2eb9b5b"  
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Shashank's Project is Completed & Working Perfectly!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "WebServer"
  }
}

# Output Public IP
output "ec2_public_ip" {
  value = aws_instance.web_server.public_ip
}
