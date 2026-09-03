##############################################
# Provider
##############################################

provider "aws" {
  region = var.aws_region
}

##############################################
# VPC Module Call
##############################################

module "vpc" {
  source = "../../modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  aws_region          = var.aws_region
  tags                = var.tags

  vpc_cidr            = var.vpc_cidr
  pod_cidr            = var.pod_cidr
  availability_zones  = var.availability_zones

  cluster_name        = var.cluster_name

  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint

  enable_flow_logs         = var.enable_flow_logs
  flow_log_retention_days  = var.flow_log_retention_days
}