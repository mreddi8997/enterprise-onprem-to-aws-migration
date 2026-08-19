# Main VPC
resource "aws_vpc" "flask_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "main-vpc"
    environment = "production"
  }
}

# Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.flask_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "public-subnet-1"
    environment = "production"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.flask_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "public-subnet-2"
    environment = "production"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.flask_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name                             = "private-subnet-1"
    environment                      = "production"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.flask_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name                             = "private-subnet-2"
    environment                      = "production"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "rds_1" {
  vpc_id            = aws_vpc.flask_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name        = "rds-subnet-1"
    environment = "production"
  }
}

resource "aws_subnet" "rds_2" {
  vpc_id            = aws_vpc.flask_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name        = "rds-subnet-2"
    environment = "production"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.flask_vpc.id

  tags = {
    Name        = "main-igw"
    environment = "production"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main_igw]

  tags = {
    Name        = "nat-eip"
    environment = "production"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main_nat" {
  subnet_id     = aws_subnet.public_subnet_1.id
  allocation_id = aws_eip.nat_eip.id
  depends_on    = [aws_internet_gateway.main_igw, aws_eip.nat_eip]

  tags = {
    Name        = "main-nat"
    environment = "production"
  }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.flask_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name        = "public-rt"
    environment = "production"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.flask_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat.id
  }

  tags = {
    Name        = "private-rt"
    environment = "production"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "rds_1_assoc" {
  subnet_id      = aws_subnet.rds_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "rds_2_assoc" {
  subnet_id      = aws_subnet.rds_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group
resource "aws_security_group" "vpc_all_traffic" {
  name        = "vpc-allow-all-test-sg"
  description = "TEST LAB ONLY: Allow all inbound and outbound traffic within/outside VPC"
  vpc_id      = aws_vpc.flask_vpc.id

  ingress {
    description      = "Allow all inbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "vpc-allow-all-sg"
    Environment = "production"
  }
}
