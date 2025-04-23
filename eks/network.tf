resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.env}-main-vpc"
    Env  = local.env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.env}-igw"
    Env  = local.env
  }
}

resource "aws_subnet" "private_zone" {
  count             = length(local.zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index * 32}.0/19"
  availability_zone = local.zones[count.index]

  tags = {
    Name                                          = "${local.env}-private-${local.zones[count.index]}-subnet"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    Env                                           = local.env
  }
}

resource "aws_subnet" "public_zone" {
  count             = length((local.zones))
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${length(aws_subnet.private_zone) * 32 + count.index * 32}.0/19"
  availability_zone = local.zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name                                          = "${local.env}-public-${local.zones[count.index]}-subnet"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    Env                                           = local.env
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.env}-eip"
    Env  = local.env
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_zone[0].id

  tags = {
    Name = "${local.env}-nat-gateway"
    Env  = local.env
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_routes" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${local.env}-private-routes"
    Env  = local.env
  }
}

resource "aws_route_table" "public_routes" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "${local.env}-public-routes"
        Env  = local.env
    }
}

resource "aws_route_table_association" "private_zone_routes" {
    count = length(local.zones)
    subnet_id = aws_subnet.private_zone[count.index].id
    route_table_id = aws_route_table.private_routes.id
}

resource "aws_route_table_association" "public_zone_routes" {
    count = length(local.zones)
    subnet_id = aws_subnet.public_zone[count.index].id
    route_table_id = aws_route_table.public_routes.id
}