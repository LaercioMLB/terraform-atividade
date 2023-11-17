resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_block
  enable_dns_support = True
  enable_dns_hostnames = True
  tags = {
    Name = "${local.stack_name}-VPC"
  }
}

resource "aws_internet_gateway" "internet_gateway" {}

resource "aws_vpn_gateway_attachment" "vpc_gateway_attachment" {
  vpc_id = aws_vpc.vpc.arn
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "Public Subnets"
    Network = "Public"
  }
}

resource "aws_route_table" "private_route_table01" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "Private Subnet AZ1"
    Network = "Private01"
  }
}

resource "aws_route_table" "private_route_table02" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "Private Subnet AZ2"
    Network = "Private02"
  }
}

resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
}

resource "aws_route" "private_route01" {
  route_table_id = aws_route_table.private_route_table01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway01.association_id
}

resource "aws_route" "private_route02" {
  route_table_id = aws_route_table.private_route_table02.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway02.association_id
}

resource "aws_nat_gateway" "nat_gateway01" {
  allocation_id = aws_ec2_fleet.nat_gateway_eip1.id
  subnet_id = aws_subnet.public_subnet01.id
  tags = {
    Name = "${local.stack_name}-NatGatewayAZ1"
  }
}

resource "aws_nat_gateway" "nat_gateway02" {
  allocation_id = aws_ec2_fleet.nat_gateway_eip2.id
  subnet_id = aws_subnet.public_subnet02.id
  tags = {
    Name = "${local.stack_name}-NatGatewayAZ2"
  }
}

resource "aws_ec2_fleet" "nat_gateway_eip1" {
  // CF Property(Domain) = "vpc"
}

resource "aws_ec2_fleet" "nat_gateway_eip2" {
  // CF Property(Domain) = "vpc"
}

resource "aws_subnet" "public_subnet01" {
  map_public_ip_on_launch = True
  availability_zone = element(data.aws_availability_zones.available.names, 0)
  cidr_block = var.public_subnet01_block
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "${local.stack_name}-PublicSubnet01"
    kubernetes.io/role/elb = 1
  }
}

resource "aws_subnet" "public_subnet02" {
  map_public_ip_on_launch = True
  availability_zone = element(data.aws_availability_zones.available.names, 1)
  cidr_block = var.public_subnet02_block
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "${local.stack_name}-PublicSubnet02"
    kubernetes.io/role/elb = 1
  }
}

resource "aws_subnet" "private_subnet01" {
  availability_zone = element(data.aws_availability_zones.available.names, 0)
  cidr_block = var.private_subnet01_block
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "${local.stack_name}-PrivateSubnet01"
    kubernetes.io/role/internal-elb = 1
  }
}

resource "aws_subnet" "private_subnet02" {
  availability_zone = element(data.aws_availability_zones.available.names, 1)
  cidr_block = var.private_subnet02_block
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "${local.stack_name}-PrivateSubnet02"
    kubernetes.io/role/internal-elb = 1
  }
}

resource "aws_route_table_association" "public_subnet01_route_table_association" {
  subnet_id = aws_subnet.public_subnet01.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet02_route_table_association" {
  subnet_id = aws_subnet.public_subnet02.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet01_route_table_association" {
  subnet_id = aws_subnet.private_subnet01.id
  route_table_id = aws_route_table.private_route_table01.id
}

resource "aws_route_table_association" "private_subnet02_route_table_association" {
  subnet_id = aws_subnet.private_subnet02.id
  route_table_id = aws_route_table.private_route_table02.id
}

resource "aws_security_group" "control_plane_security_group" {
  description = "Cluster communication with worker nodes"
  vpc_id = aws_vpc.vpc.arn
}

