#  S3  storage


# terraform {
#   backend "s3" {
#     bucket         = "sysdyne-terraform-states"            # S3 Bucket for storing Terraform state
#     key            = var.state_key # Key based on environment
#     region         = "us-east-1"                      # AWS region of the S3 bucket
#     encrypt        = true                             # Enable server-side encryption
#     dynamodb_table = "terraform-state-lock"           # DynamoDB table for state locking
#   }
# }


# terraform {
#   backend "local" {
#     path = "public_api_state/default/terraform.tfstate"  # Default or placeholder path
#   }
# }


terraform {
  backend "azurerm" {}
}
