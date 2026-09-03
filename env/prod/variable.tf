##############################################
# General
##############################################

variable "project_name" {
  description = "Name of the project, used as a prefix for resource naming"
  type        = string
  default     = "chat-aws-foundation"
}

variable "environment" {
  description = "Environment name for this root module (fixed as prod, but kept as a variable for consistency with the module contract)"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region to deploy the prod environment into"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common tags applied to all resources in prod"
  type        = map(string)
  default = {
    Project     = "chat-aws-foundation"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}

##############################################
# Networking - CIDRs & AZs
##############################################

variable "vpc_cidr" {
  description = "Primary CIDR block for the prod VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pod_cidr" {
  description = "Secondary CIDR block dedicated to EKS pod IPs in prod"
  type        = string
  default     = "100.64.0.0/16"
}

variable "availability_zones" {
  description = "AZs to deploy prod subnets into"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

##############################################
# EKS-related
##############################################

variable "cluster_name" {
  description = "Planned EKS cluster name for prod, used for subnet auto-discovery tags"
  type        = string
  default     = "chat-aws-foundation-prod"
}

##############################################
# VPC Endpoints
##############################################

variable "enable_dynamodb_endpoint" {
  description = "Whether to create the DynamoDB gateway endpoint in prod"
  type        = bool
  default     = false
}

##############################################
# Flow Logs
##############################################

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs in prod"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "CloudWatch Logs retention period for prod VPC flow logs"
  type        = number
  default     = 90
}