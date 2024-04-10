resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16" 
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "LibreChat-VPC01"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24" 
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24" 
}

resource "aws_subnet" "subnet_3" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24" 
}
