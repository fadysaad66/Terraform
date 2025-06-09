provider "aws" {
  
  access_key = "AKIAS4KVQ5GFYFLPWQ5S"
  secret_key = "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"

  region  = "us-east-1"
}

// vpc creation 
 resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

//subnets 
// sub1 , sub3 are  public 
// sub2 , sub 4 are private
resource "aws_subnet" "sub1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/20"
   availability_zone ="us-east-1a"
  tags = {
    Name = "Mainsub1"
  }
}
// internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main"
  }
}

//route table 
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "routemain"
  }
  }

 //subnet associated to route table 

  resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.r.id
}


// security group for public subnet 
resource "aws_security_group" "SGsub1" {
    vpc_id = aws_vpc.main.id 
    name = "SGsub1"
    ingress  {
    cidr_blocks = ["0.0.0.0/0"]
      from_port = 80
      protocol = "tcp"
      to_port = 80
    } 
    ingress  {
    cidr_blocks = ["0.0.0.0/0"]
      from_port = 443
      protocol = "tcp"
      to_port = 443
    } 
    ingress  {
    cidr_blocks = ["0.0.0.0/0"]
      from_port = 22
      protocol = "tcp"
      to_port = 22
    } 
    egress  {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = 0
      protocol = "-1"
      to_port = 0
    } 
}

resource "aws_network_interface" "nec" {
  subnet_id       = aws_subnet.sub1.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.SGsub1.id]

  
}

// create e-ip
resource "aws_eip" "eip_sub2" {
  domain = "vpc"  
  network_interface = aws_network_interface.nec.id
  associate_with_private_ip = "10.0.0.50"

  depends_on = [aws_internet_gateway.gw]
  instance = aws_instance.ec2.id
  tags = {
    Name = "eipsub2"
  }
}

//Create Ubuntu server and install/enable apache2

 resource "aws_instance" "ec2" {
  ami               = "ami-0885b1f6bd170450c"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "key123"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nec.id
  }

   user_data = <<-EOF
		#! /bin/bash
   sudo apt-get update
		sudo apt-get install -y apache2
		sudo systemctl start apache2
		sudo systemctl enable apache2
		echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
	EOF

tags = {
    Name = "web-server"
  }
 }

