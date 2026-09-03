##############################################
# VPC
##############################################

resource "aws_vpc" "this" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = merge(var.tags, {
        Name = "${var.project_name}-${var.environment}-vpc"
    })
}

# Secondary CIDR block dedicated to pod IPs (VPC CNI custom networking)
resource "aws_vpc_ipv4_cidr_block_association" "pods" {
    vpc_id = aws_vpc.this.id
    cidr_block = var.pod_cidr
}

##############################################
# Subnet CIDR calculations
##############################################

locals {
  az_count = length(var.availability_zones)

  # Primary CIDR split into /20s (assuming a /16 vpc_cidr):
  # index 0-2 public, 3-5 private-app, 6-8 private-data
  public_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, i)
  ]
  private_app_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 3)
  ]
  private_data_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 6)
  ]

  # Secondary CIDR split into /18s for pod subnets, one per AZ
  pod_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.pod_cidr, 2, i)
  ]

  az_map = { for idx, az in var.availability_zones : az => idx }
}

##############################################
# Public Subnets
##############################################

resource "aws_subnet" "public" {
    for_each = local.az_map

    vpc_id = aws_vpc.this.id
    cidr_block = local.public_subnet_cidrs[each.value]
    availability_zone = each.key
    map_public_ip_on_launch = true

    tags = merge(var.tags, {
        Name = "${var.project_name}-${var.environment}-public-${each.key}"
        Tier = "public"
        "kubernetes.io/role/elb"                    = "1"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    })  
}

##############################################
# Private Data Subnets (RDS, ElastiCache)
##############################################
resource "aws_subnet" "private_data" {
  for_each = local.az_map

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_data_subnet_cidrs[each.value]
  availability_zone = each.key

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-data-${each.key}"
    Tier = "private-data"
  })
}

##############################################
# Pod Subnets (secondary CIDR, EKS CNI custom networking)
##############################################

resource "aws_subnet" "pods" {
  for_each = local.az_map

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.pod_subnet_cidrs[each.value]
  availability_zone = each.key

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-pods-${each.key}"
    Tier = "pods"
  })

  depends_on = [aws_vpc_ipv4_cidr_block_association.pods]
}


##############################################
# Internet Gateway
##############################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}
##############################################
# NAT Gateways (one per AZ)
##############################################

resource "aws_eip" "nat" {
  for_each = local.az_map
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${each.key}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = local.az_map

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

##############################################
# Route Tables - Public
##############################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = local.az_map

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

##############################################
# Route Tables - Private App (per AZ, own NAT)
##############################################

resource "aws_route_table" "private_app" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-app-rt-${each.key}"
  })
}

resource "aws_route" "private_app_nat" {
  for_each = local.az_map

  route_table_id         = aws_route_table.private_app[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private_app" {
  for_each = local.az_map

  subnet_id      = aws_subnet.private_app[each.key].id
  route_table_id = aws_route_table.private_app[each.key].id
}

# Pod subnets share the same route table as their AZ's app subnet
resource "aws_route_table_association" "pods" {
  for_each = local.az_map

  subnet_id      = aws_subnet.pods[each.key].id
  route_table_id = aws_route_table.private_app[each.key].id
}

##############################################
# Route Tables - Private Data (per AZ, isolated)
##############################################

resource "aws_route_table" "private_data" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-data-rt-${each.key}"
  })
}

resource "aws_route" "private_data_nat" {
  for_each = local.az_map

  route_table_id         = aws_route_table.private_data[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private_data" {
  for_each = local.az_map

  subnet_id      = aws_subnet.private_data[each.key].id
  route_table_id = aws_route_table.private_data[each.key].id
}

##############################################
# VPC Endpoints
##############################################

# Gateway endpoint - S3 (free, attach to all private route tables)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = concat(
    [for rt in aws_route_table.private_app : rt.id],
    [for rt in aws_route_table.private_data : rt.id]
  )

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-s3-endpoint" })
}

# Gateway endpoint - DynamoDB (optional, only if the app actually uses DynamoDB)
resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"

  route_table_ids = concat(
    [for rt in aws_route_table.private_app : rt.id],
    [for rt in aws_route_table.private_data : rt.id]
  )

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-dynamodb-endpoint" })
}

# Security group shared by interface endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-${var.environment}-vpce-"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from within VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.pod_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-vpce-sg" })
}

# Interface endpoints (paid, per-hour + data processing)
resource "aws_vpc_endpoint" "interface" {
  for_each = toset([
    "ecr.api",
    "ecr.dkr",
    "sts",
    "secretsmanager",
    "logs",
  ])

  vpc_id               = aws_vpc.this.id
  service_name         = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type    = "Interface"
  subnet_ids           = [for s in aws_subnet.private_app : s.id]
  security_group_ids   = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled  = true

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-${each.value}-endpoint" })
}

##############################################
# VPC Flow Logs
##############################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/${var.project_name}-${var.environment}-flow-logs"
  retention_in_days = var.flow_log_retention_days

  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.project_name}-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn     = aws_iam_role.flow_logs[0].arn
  log_destination  = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type     = "ALL"
  vpc_id           = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-flow-log" })
}