provider "aws" {
 access_key = "value"
 secret_key = "value"
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
resource "aws_subnet" "sub2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.16.0/20"
   availability_zone ="us-east-1a"
  tags = {
    Name = "Mainsub2"
  }
}

resource "aws_subnet" "sub3" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.32.0/20"
   availability_zone ="us-east-1b"
  tags = {
    Name = "Mainsub3"
  }
}
resource "aws_subnet" "sub4" {
  vpc_id     = aws_vpc.main.id
   
  cidr_block = "10.0.48.0/20"
   availability_zone ="us-east-1b"
    
  tags = {
    Name = "Mainsub4"
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



// create e-ip
resource "aws_eip" "eip_sub1" {
  vpc = true  
  depends_on = [ aws_internet_gateway.gw ]

  tags = {
    Name = "eipsub2"
  }
}
resource "aws_eip" "eip_sub3" {
  vpc = true  
  depends_on = [ aws_internet_gateway.gw ]
  tags = {
    Name = "eipsub4"
  }
}
 // create nat gateway
 # associate  eip  with  each public subnet sub1,sub3
 
 resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.eip_sub1.id   
  subnet_id     = aws_subnet.sub1.id
  tags = {
    Name = "nat1"
  }
}
resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.eip_sub3.id
  subnet_id     = aws_subnet.sub3.id
  tags = {
    Name = "nat2"
  }
}

   //subnet associated to route table 

  resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.r.id
}

  resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.sub3.id
  route_table_id = aws_route_table.r.id
}
 // subnet associated with nat gateway 
 resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.main.id
   route {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id =aws_nat_gateway.nat1.id
   }
   tags = {
    Name = "natsub2"
  }
}
resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.main.id
   route {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id =aws_nat_gateway.nat2.id
   }
   tags = {
    Name = "natsub4"
  }
}
// network AcL for public subnets

resource "aws_network_acl" "NACLsub1" {
  vpc_id = aws_vpc.main.id
subnet_ids  =  ["{aws_subnet.sub1.id}" ] 
ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/20"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.0.0/20"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "10.0.0.0/20"
    from_port  = 22
    to_port    = 22
  }
  egress {
    protocol   = "-1"
    rule_no    = 400
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

tags = {
    Name = "sub1"
  }

}

resource "aws_network_acl" "NACLsub3" {
  vpc_id = aws_vpc.main.id
  subnet_ids    =  ["{aws_subnet.sub3.id}"]
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.32.0/20"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.32.0/20"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "10.0.32.0/20"
    from_port  = 22
    to_port    = 22
  }
  egress {
    protocol   = "-1"
    rule_no    = 400
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "sub3"
  }

}
// security group for public subnet 
resource "aws_security_group" "SGsub1" {
    vpc_id = aws_vpc.main.id 
    name = "SGsub1"
    ingress  {
    cidr_blocks = ["10.0.0.0/20"]
      from_port = 80
      protocol = "tcp"
      to_port = 80
    } 
    ingress  {
    cidr_blocks = ["10.0.0.0/20"]
      from_port = 443
      protocol = "tcp"
      to_port = 443
    } 
    ingress  {
    cidr_blocks = ["10.0.0.0/20"]
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
resource "aws_security_group" "SGsub3" {
    vpc_id = aws_vpc.main.id 
    name = "SGsub3"
    ingress  {
    cidr_blocks = ["10.0.32.0/20"]
      from_port = 80
      protocol = "tcp"
      to_port = 80
    } 
    ingress  {
    cidr_blocks = ["10.0.32.0/20"]
      from_port = 443
      protocol = "tcp"
      to_port = 443
    } 
    ingress  {
    cidr_blocks = ["10.0.32.0/20"]
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

// create Netwoel ACL for private subnets 

resource "aws_network_acl" "NACLsub2" {
  vpc_id = aws_vpc.main.id
  subnet_ids    = ["{aws_subnet.sub2.id}"]
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.16.0/20"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.16.0/20"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "10.0.16.0/20"
    from_port  = 22
    to_port    = 22
  }
  egress {
    protocol   = "-1"
    rule_no    = 400
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
tags = {
    Name = "sub2"
  }
}

resource "aws_network_acl" "NACLsub4" {
  vpc_id = aws_vpc.main.id
  subnet_ids = ["{aws_subnet.sub4.id}"]
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.48.0/20"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.48.0/20"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "10.0.48.0/20"
    from_port  = 22
    to_port    = 22
  }
  egress {
    protocol   = "-1"
    rule_no    = 400
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "sub4"
  }

}

// create security groups for private subnets 

resource "aws_security_group" "SGsub2" {
    vpc_id = aws_vpc.main.id 
    name = "SGsub2"
    ingress  {
    cidr_blocks = ["10.0.16.0/20"]
      from_port = 80
      protocol = "tcp"
      to_port = 80
    } 
    ingress  {
    cidr_blocks = ["10.0.16.0/20"]
      from_port = 443
      protocol = "tcp"
      to_port = 443
    } 
    ingress  {
    cidr_blocks = ["10.0.16.0/20"]
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
resource "aws_security_group" "SGsub4" {
    vpc_id = aws_vpc.main.id 
    name = "SGsub4"
    ingress  {
    cidr_blocks = ["10.0.48.0/20"]
      from_port = 80
      protocol = "tcp"
      to_port = 80
    } 
    ingress  {
    cidr_blocks = ["10.0.48.0/20"]
      from_port = 443
      protocol = "tcp"
      to_port = 443
    } 
    ingress  {
    cidr_blocks = ["10.0.48.0/20"]
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

