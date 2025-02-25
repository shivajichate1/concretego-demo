# variables.tf

variable "env" {
  description = "Environment name (dev, staging, ga, prod)"
  type        = string
}


variable "prod_regions" {
  type    = list(string)
  default = ["us-north-central", "us-south-central", "us-east", "au-east"]
}



# Map environments to their Azure Web App service names
variable "origin_map" {
  type = map(string)
  default = {
    dev       = "concretego-api-dev.azurewebsites.net"
    staging   = "concretego-api-staging.azurewebsites.net"
    ga        = "concretego-api-ga.azurewebsites.net"
    us-north-central = "concretego-api-north-central-us.azurewebsites.net"
    us-south-central = "concretego-api-south-central-us.azurewebsites.net"
    us-east   = "concretego-api-east-us.azurewebsites.net"
    au-east   = "concretego-api-east-au.azurewebsites.net"
  }
}

variable "priority_map" {
  type = map(list(string))
  default = {
    "us-north-central" = ["us-north-central", "us-south-central", "us-east", "au-east"]
    "us-south-central" = ["us-south-central", "us-north-central", "us-east", "au-east"]
    "us-east"          = ["us-east", "us-north-central", "us-south-central", "au-east"]
    "au-east"          = ["au-east", "us-east", "us-north-central", "us-south-central"]
  }
}

# Production region mapping (used only in production)
variable "prod_regions_map" {
  type = map(string)
  default = {
    0 = "us-north-central"
    1 = "us-south-central"
    2 = "us-east"
    3 = "au-east"
  }
}

# Non-production (Dev/Staging) regions (Only one origin per env)
variable "non_prod_regions" {
  type    = list(string)
  default = [
    "dev-api.azurewebsites.net",       # Dev
    "staging-api.azurewebsites.net"    # Staging
  ]
}


# frontdoor

# Define Azure Resource Groups for each environment
variable "resource_group_map" {
  type = map(string)
  default = {
    prod    = "concretego-api"
    dev     = "concretego-dev"
    staging = "concretego-staging"
    ga      = "concretego-ga"
  }
}



# Define Azure Front Door SKU mapping for each environment
variable "frontdoor_sku_map" {
  type = map(string)
  default = {
    prod    = "Standard_AzureFrontDoor"        # Premium_AzureFrontDoor  Standard_AzureFrontDoor
    dev     = "Standard_AzureFrontDoor"
    staging = "Standard_AzureFrontDoor"         
    ga      = "Standard_AzureFrontDoor"
  }
}



# AWS 

variable "aws_region" {
  description = "AWS region for Route 53"
  type        = string
  default     = "us-east-1"  
}


variable "aws_route53_zone_id" {
  description = "AWS Route 53 Zone ID"
  type        = string
  default     = "Z10414221EAE9E7BKFO1"  #  Route 53 hosted zone ID 
}

