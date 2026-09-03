##############################################
# General
##############################################

variable "project_name" {
  description = "Name of the project, used as a prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into (used for VPC endpoint service names)"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

##############################################
# Networking - CIDRs & AZs
##############################################

variable "vpc_cidr" {
  description = "Primary CIDR block for the VPC (used for public, private-app, and private-data subnets)"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "pod_cidr" {
  description = "Secondary CIDR block dedicated to EKS pod IPs (CNI custom networking), e.g. 100.64.0.0/16"
  type        = string

  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "pod_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of AZs to deploy subnets into. Must have exactly 3 for this module's design."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "This module is designed for exactly 3 AZs."
  }
}

##############################################
# EKS-related
##############################################

variable "cluster_name" {
  description = "Planned/actual EKS cluster name, used for subnet auto-discovery tags (kubernetes.io/cluster/<name>)"
  type        = string
}

##############################################
# VPC Endpoints
##############################################

variable "enable_dynamodb_endpoint" {
  description = "Whether to create the DynamoDB gateway endpoint. Only relevant if the app itself uses DynamoDB for chat data (messages/sessions/presence)."
  type        = bool
  default     = false
}

##############################################
# Flow Logs
##############################################

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs to CloudWatch"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "CloudWatch Logs retention period for VPC flow logs"
  type        = number
  default     = 30
}