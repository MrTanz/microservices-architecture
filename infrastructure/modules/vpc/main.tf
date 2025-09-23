# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16" # 65536 indirizzi IP (da 10.0.0.0 a 10.0.255.255).

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name"      = "${var.project_name}-vpc-${var.env}"
    Environment = var.env
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name"      = "${var.project_name}-igw-${var.env}"
    Environment = var.env
  }
}

data "aws_availability_zones" "availability_zones" {
  state = "available"
}

locals {
  first_availability_zone  = data.aws_availability_zones.availability_zones.names[0]
  second_availability_zone = data.aws_availability_zones.availability_zones.names[1]
}

# PUBBLIC SUBNET
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24" # 256 ip riservati a questa subnet
  map_public_ip_on_launch = true          # EC2 riceve automaticamente un indirizzo IP pubblico.
  availability_zone       = local.first_availability_zone

  tags = {
    "Name" = "public-subnet-a-${var.env}"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24" # 256 ip riservati a questa subnet
  map_public_ip_on_launch = true          # EC2 riceve automaticamente un indirizzo IP pubblico.
  availability_zone       = local.second_availability_zone

  tags = {
    "Name"      = "public-subnet-b-${var.env}"
    Environment = var.env
  }
}

# PRIVATE SUBNET
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24" # 256 ip riservati a questa subnet
  availability_zone = local.first_availability_zone

  tags = {
    "Name"      = "${var.project_name}-private-subnet-a-${var.env}"
    Environment = var.env
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24" # 256 ip riservati a questa subnet
  availability_zone = local.second_availability_zone

  tags = {
    "Name"      = "${var.project_name}-private-subnet-b-${var.env}"
    Environment = var.env
  }
}

# ROUTE TABLE PUBBLICA IN QUANTO LEGATA ALL'INTERNET GATEWAY
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0" # accesso da qualsiasi IP
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    "Name"      = "${var.project_name}-public-route-table-${var.env}"
    Environment = var.env
  }
}

# ROUTE TABLE PRIVATA
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name"      = "${var.project_name}-private-route-table-${var.env}"
    Environment = var.env
  }
}

# ASSOCIAZIONE TABELLA PUBBLICA ALLA SUBNET
resource "aws_route_table_association" "public_route_table_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# ASSOCIAZIONE TABELLA PRIVATA ALLA SUBNET
resource "aws_route_table_association" "private_route_table_a_association" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_b_association" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table.id
}

# VPC ENDPOINTS
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "${var.project_name}-vpc-endpoint-sg-${var.env}"
  description = "Allow HTTPS from VPC"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-vpc-endpoint-sg-${var.env}"
    Environment = var.env
  }
}

# SSM ENDPOINT
resource "aws_vpc_endpoint" "vpc_endpoint_ssm" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ssm-endpoint-${var.env}"
    Environment = var.env
  }
}

# ECR ENDPOINT
resource "aws_vpc_endpoint" "vpc_endpoint_ecr_dkr" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ecr-dkr-endpoint-${var.env}"
    Environment = var.env
  }
}

resource "aws_vpc_endpoint" "vpc_endpoint_ecr_api" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    "Name"      = "${var.project_name}-ecr-api-endpoint-${var.env}"
    Environment = var.env
  }
}

# S3 ENDPOINT
resource "aws_vpc_endpoint" "vpc_endpoint_s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_route_table.id
  ]

  tags = {
    Name        = "${var.project_name}-s3-endpoint-${var.env}"
    Environment = var.env
  }
}

# CLOUDWATCH ENDPOINT
resource "aws_vpc_endpoint" "vpc_endpoint_cloudwatch_logs" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-cloudwatch-logs-endpoint-${var.env}"
    Environment = var.env
  }
}

# SQS ENDPOINT
resource "aws_vpc_endpoint" "vpc_endpoint_sqs" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-sqs-endpoint-${var.env}"
    Environment = var.env
  }
}
