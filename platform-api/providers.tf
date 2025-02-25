terraform {
  required_providers {
    azurerm = {
      version = "= 3.88.0"
    }
  }
}


provider "azurerm" {
  features {}
  skip_provider_registration = true
}


provider "aws" {
  region = var.aws_region
}

