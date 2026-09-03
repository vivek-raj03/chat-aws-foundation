##############################################
# VPC
##############################################

output "vpc_id" {
  description = "ID of the prod VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "Primary CIDR block of the prod VPC"
  value       = module.vpc.vpc_cidr
}

output "pod_cidr" {
  description = "Secondary CIDR block for pod IPs in prod"
  value       = module.vpc.pod_cidr
}

##############################################
# Subnets
##############################################

output "public_subnet_ids" {
  description = "Map of AZ -> public subnet ID"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Map of AZ -> private app-tier subnet ID (EKS worker nodes)"
  value       = module.vpc.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "Map of AZ -> private data-tier subnet ID (RDS, ElastiCache)"
  value       = module.vpc.private_data_subnet_ids
}

output "pod_subnet_ids" {
  description = "Map of AZ -> pod subnet ID"
  value       = module.vpc.pod_subnet_ids
}

##############################################
# Routing
##############################################

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.vpc.public_route_table_id
}

output "private_app_route_table_ids" {
  description = "Map of AZ -> private app-tier route table ID"
  value       = module.vpc.private_app_route_table_ids
}

output "private_data_route_table_ids" {
  description = "Map of AZ -> private data-tier route table ID"
  value       = module.vpc.private_data_route_table_ids
}

##############################################
# NAT / Internet Gateway
##############################################

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "Map of AZ -> NAT Gateway ID"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "Map of AZ -> NAT Gateway public IP"
  value       = module.vpc.nat_gateway_public_ips
}

##############################################
# Security
##############################################

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group used by interface VPC endpoints"
  value       = module.vpc.vpc_endpoints_security_group_id
}