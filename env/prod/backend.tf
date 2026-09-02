# terraform {
#   backend "s3" {
#     bucket       = "chat-aws-foundation-tfstate-prod"
#     key          = "prod/vpc/terraform.tfstate"
#     region       = "us-east-1"
#     encrypt      = true
#     use_lockfile = true   # native S3 locking, replaces dynamodb_table
#   }
# }