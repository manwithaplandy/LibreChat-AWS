resource "aws_eip" "nat" {}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.subnet_1.id
}

resource "aws_route_table" "nat" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }

    tags = {
        Name = "NAT route table"
    }
}

resource "aws_route_table_association" "private_subnet_1" {
    subnet_id      = aws_subnet.subnet_1.id
    route_table_id = aws_route_table.nat.id
}

resource "aws_route_table_association" "private_subnet_2" {
    subnet_id      = aws_subnet.subnet_2.id
    route_table_id = aws_route_table.nat.id
}

resource "aws_route_table_association" "private_subnet_3" {
    subnet_id      = aws_subnet.subnet_3.id
    route_table_id = aws_route_table.nat.id
}
