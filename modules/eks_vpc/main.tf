module "eks_vpc" {
  source          = "./modules/eks_vpc"
  vpc_block       = "192.168.0.0/16"  # Substitua pelos valores desejados
  public_subnet1  = "192.168.0.0/18"
  public_subnet2  = "192.168.64.0/18"
  private_subnet1 = "192.168.128.0/18"
  private_subnet2 = "192.168.192.0/18"
  stack_name      = "application-cluster"
}

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = module.eks_vpc.vpc_id
  cidr_block              = module.eks_vpc.public_subnet1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${module.eks_vpc.stack_name}-PublicSubnet01"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = module.eks_vpc.vpc_id
  cidr_block              = module.eks_vpc.public_subnet2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${module.eks_vpc.stack_name}-PublicSubnet02"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id                  = module.eks_vpc.vpc_id
  cidr_block              = module.eks_vpc.private_subnet1
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${module.eks_vpc.stack_name}-PrivateSubnet01"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id                  = module.eks_vpc.vpc_id
  cidr_block              = module.eks_vpc.private_subnet2
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${module.eks_vpc.stack_name}-PrivateSubnet02"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_security_group" "control_plane_sg" {
  name        = "${module.eks_vpc.stack_name}-ControlPlaneSecurityGroup"
  description = "Cluster communication with worker nodes"
  vpc_id      = module.eks_vpc.vpc_id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = module.eks_vpc.vpc_id

  tags = {
    Name    = "Public Subnets"
    Network = "Public"
  }
}

resource "aws_route_table" "private_route_table_1" {
  vpc_id = module.eks_vpc.vpc_id

  tags = {
    Name    = "Private Subnet AZ1"
    Network = "Private01"
  }
}

resource "aws_route_table" "private_route_table_2" {
  vpc_id = module.eks_vpc.vpc_id

  tags = {
    Name    = "Private Subnet AZ2"
    Network = "Private02"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_igw.id
}

resource "aws_route" "private_route_1" {
  route_table_id         = aws_route_table.private_route_table_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
}

resource "aws_route" "private_route_2" {
  route_table_id         = aws_route_table.private_route_table_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_2.id
}

resource "aws_nat_gateway" "nat_gateway_1" {
  depends_on = [
    aws_vpc_attachment.eks_vpc_attachment,
    aws_eip.nat_gateway_eip_1
  ]

  allocation_id = aws_eip.nat_gateway_eip_1.id
  subnet_id     = aws_subnet.public_subnet1.id
}

resource "aws_nat_gateway" "nat_gateway_2" {
  depends_on = [
    aws_vpc_attachment.eks_vpc_attachment,
    aws_eip.nat_gateway_eip_2
  ]

  allocation_id = aws_eip.nat_gateway_eip_2.id
  subnet_id     = aws_subnet.public_subnet2.id
}

resource "aws_eip" "nat_gateway_eip_1" {
  vpc = true
}

resource "aws_eip" "nat_gateway_eip_2" {
  vpc = true
}

resource "aws_instance" "ec2-public" {
  ami             = ""
  instance_type   = "t4g.small"  
  subnet_id       = module.eks_vpc.public_subnet1

  tags = {
    Name = "InstanciaPublica"
  }
}

resource "aws_instance" "ec2-private" {
  ami             = ""
  instance_type   = "t4g.small"  
  subnet_id       = module.eks_vpc.private_subnet1


  tags = {
    Name = "InstanciaPrivada"
  }
}
