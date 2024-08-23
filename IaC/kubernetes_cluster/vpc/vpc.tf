#Create Virtual Private Cloud
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

#Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    "Name" = "${var.vpc_name}-igw"
  }
}

#Create Public Subnets
resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.vpc.id
  count = length(var.public_subnet_cidrs)
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = var.region_azs[count.index]
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch = true

  tags = {
    "Name" : "${var.vpc_name}-public-subnet-${substr(var.region_azs[count.index], -1, 1)}"
    "kubernetes.io/cluster/${var.cluster_name}" : "shared"
    "kubernetes.io/role/elb" : 1
    "karpenter.sh/discovery" : var.cluster_name
  }
}

# #Create Private Subnets
# resource "aws_subnet" "private_subnets" {
#   vpc_id = aws_vpc.vpc.id
#   count = length(var.private_subnet_cidrs)
#   cidr_block = var.private_subnet_cidrs[count.index]
#   availability_zone = var.region_azs[count.index]
#   enable_resource_name_dns_a_record_on_launch = true

#   tags = {
#     "Name" : "${var.vpc_name}-private-subnet-${substr(var.region_azs[count.index], -1, 1)}"
#     "kubernetes.io/cluster/${var.cluster_name}" : "shared"
#     "kubernetes.io/role/internal-elb" : 1
#     "karpenter.sh/discovery" : var.cluster_name
#   }
# }

#Create public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" : "${var.vpc_name}-public-route-table"
    "kubernetes.io/cluster/${var.cluster_name}" : "shared"
  }
}

# resource "aws_eip" "nat_gateway_eip" {
#   count = length(var.private_subnet_cidrs)
#   domain = "vpc"
# }

# resource "aws_nat_gateway" "nat_gateway" {
#   count = length(var.private_subnet_cidrs)
#   allocation_id = aws_eip.nat_gateway_eip[count.index].id
#   subnet_id = aws_subnet.public_subnets[count.index].id

#   tags = {
#     "Name" = "${var.vpc_name}-nat-gateway-${substr(var.region_azs[count.index],-1,1)}"
#   }
# }

# #Create private route tables
# resource "aws_route_table" "private_route_tables" {
#   vpc_id = aws_vpc.vpc.id
#   count = length(var.private_subnet_cidrs)

#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
#   }

#   tags = {
#     "Name" : "${var.vpc_name}-private-route-table-${substr(var.region_azs[count.index], -1, 1)}"
#     "kubernetes.io/cluster/${var.cluster_name}" : "shared"
#   }
# }

resource "aws_route_table_association" "public_subnet_route_association" {
  count = length(var.public_subnet_cidrs)
  subnet_id = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# resource "aws_route_table_association" "private_subnet_route_associations" {
#   count = length(var.private_subnet_cidrs)
#   subnet_id = aws_subnet.private_subnets[count.index].id
#   route_table_id = aws_route_table.private_route_tables[count.index].id
# }

### vpc endpoint
resource "aws_security_group" "vpc_endpoint_sg" {
  ingress = [{
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
    description      = "same vpc allow"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
    }]

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "alow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.vpc_name}-vpc-endpoint-sg"
  }
}

resource "aws_vpc_endpoint" "ecr-api" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.current_region}.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_sg.id,
  ]

  # subnet_ids = tolist(aws_subnet.private_subnets[*].id)
  subnet_ids = tolist(aws_subnet.public_subnets[*].id)

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr-dkr" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.current_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_sg.id,
  ]

  # subnet_ids = tolist(aws_subnet.private_subnets[*].id)
  subnet_ids = tolist(aws_subnet.public_subnets[*].id)

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.current_region}.s3"
  vpc_endpoint_type = "Gateway"

  # route_table_ids = tolist(aws_route_table.private_route_tables[*].id)
  route_table_ids = [aws_route_table.public_route_table.id]
}