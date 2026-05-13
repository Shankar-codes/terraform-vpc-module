#VPC creation   
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = merge(
    var.vpc_tags,
    local.common_tags,
    {
    Name = local.common_name_suffix
  }
  )
}

# IGW - Internet Gateway creation
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.igttags,
    local.common_tags,
    {
    Name = local.common_name_suffix
  }
  )
}

# public subnet creation
resource "aws_subnet" "public" {
  count=length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.public_subnet_tags,
    local.common_tags,
    {
    Name = "${local.common_name_suffix}-public-${local.az_names[count.index]}"
  }
  )
}

# private subnet creation
resource "aws_subnet" "private" {
  count=length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = local.az_names[count.index]
  tags = merge(
    var.private_subnet_tags,
    local.common_tags,
    {
    Name = "${local.common_name_suffix}-private-${local.az_names[count.index]}"
  }
  )
}

# database subnet creation
resource "aws_subnet" "database" {
  count=length(var.database_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = local.az_names[count.index]
  tags = merge(
    var.database_subnet_tags,
    local.common_tags,
    {
    Name = "${local.common_name_suffix}-database-${local.az_names[count.index]}"
  }
  )
}

# public route table creation
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.public_route_table_tags,
    local.common_tags,
    {
    Name = "${local.common_name_suffix}-public"
  }
  )
}

#private route table creation
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.private_route_table_tags,
    local.common_tags,
    {
    Name = "${local.common_name_suffix}-private"
  }
  )
}

# database route table creation
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.database_route_table_tags,
    local.common_tags,
    {
    Name = "${local.common_name_suffix}-database"
  }
  )
}

# associate public subnet with public route table
resource "aws_route" "public" {
  route_table_id              = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id      = aws_internet_gateway.main.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(
    var.eip_tags,
    local.common_tags,
    {
    Name = "${local.common_name_suffix}-nat"
  }
  )
}

# nat gateway creation
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.nat_gateway_tags,
    local.common_tags,
    {
    Name = "${local.common_name_suffix}"
  }
  )
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

# private egress route through NAT Gateway
resource "aws_route" "private" {
  route_table_id              = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id      = aws_nat_gateway.nat.id
}

# database egress route through NAT Gateway
resource "aws_route" "database" {
  route_table_id              = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id      = aws_nat_gateway.nat.id
}

# associate subnets with public route tables
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# associate subnets with private route tables
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# associate subnets with database route tables
resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}