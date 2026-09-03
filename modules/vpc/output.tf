##############################################
# VPC
##############################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Primary CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "pod_cidr" {
  description = "Secondary CIDR block associated with the VPC, dedicated to pod IPs"
  value       = var.pod_cidr
}

##############################################
# Subnets
##############################################

output "public_subnet_ids" {
  description = "Map of AZ -> public subnet ID"
  value       = { for az, subnet in aws_subnet.public : az => subnet.id }
}

output "private_app_subnet_ids" {
  description = "Map of AZ -> private app-tier subnet ID (EKS worker nodes)"
  value       = { for az, subnet in aws_subnet.private_app : az => subnet.id }
}

output "private_data_subnet_ids" {
  description = "Map of AZ -> private data-tier subnet ID (RDS, ElastiCache)"
  value       = { for az, subnet in aws_subnet.private_data : az => subnet.id }
}

output "pod_subnet_ids" {
  description = "Map of AZ -> pod subnet ID (secondary CIDR, EKS CNI custom networking)"
  value       = { for az, subnet in aws_subnet.pods : az => subnet.id }
}

##############################################
# Routing
##############################################

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "Map of AZ -> private app-tier route table ID"
  value       = { for az, rt in aws_route_table.private_app : az => rt.id }
}

output "private_data_route_table_ids" {
  description = "Map of AZ -> private data-tier route table ID"
  value       = { for az, rt in aws_route_table.private_data : az => rt.id }
}

##############################################
# NAT / Internet Gateway
##############################################

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "Map of AZ -> NAT Gateway ID"
  value       = { for az, nat in aws_nat_gateway.this : az => nat.id }
}

output "nat_gateway_public_ips" {
  description = "Map of AZ -> NAT Gateway public (Elastic) IP"
  value       = { for az, eip in aws_eip.nat : az => eip.public_ip }
}

##############################################
# Security
##############################################

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group used by interface VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}