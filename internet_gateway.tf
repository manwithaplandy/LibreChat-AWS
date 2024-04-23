resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "route" {
  route_table_id         = aws_vpc.vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_vpc.vpc.main_route_table_id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_vpc.vpc.main_route_table_id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.subnet_3.id
  route_table_id = aws_vpc.vpc.main_route_table_id
}
