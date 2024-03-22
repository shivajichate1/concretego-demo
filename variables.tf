variable "env" {
  type    = string
  default = "Demo"
}
variable "hostname" {
  type    = string
  default = "test.com"
}

variable "location" {
  type    = string
  default = "North Central US"
}

variable "prefix" {
  type    = string
  default = "cgdemo"
}



variable "tags" {
  description = "Default tags to apply to all resources."
  type        = map(any)
}

variable "app_service_plans" {
  description = "Map of Azure App Service Plan configurations"
  type        = map(object({
    sku_name = string
  }))
  default = {
    cgapps_asp = {
      sku_name = "B1"
    }
    cgfuncation_asp = {
      sku_name = "B1"
    }
  }
}

variable "storage_accounts" {
  description = "Map of storage account configurations"
  type        = map(object({
    account_tier             = string
    account_replication_type = string
    account_kind             = string
    access_tier              = string
  }))
  default = {
    concretego_storage_account = {
      account_tier             = "Standard"
      account_replication_type = "LRS"
      account_kind             = "StorageV2"
      access_tier              = "Hot"
    }
    eventhub_storage_account = {
      account_tier             = "Standard"
      account_replication_type = "LRS"
      account_kind             = "StorageV2"
      access_tier              = "Hot"
    }
  }
}


variable "redis_caches" {
  description = "Map of Azure Redis Cache configurations"
  type        = map(object({
    sku_name            = string
    capacity            = number
    family              = string
    maxmemory_reserved  = number
    maxmemory_policy    = string
  }))
  default = {
    concretego_redis_cache = {
      sku_name            = "Standard"
      capacity            = 0
      family              = "C"
      maxmemory_reserved  = 35
      maxmemory_policy    = "volatile-lru"
    }

    # Add more configurations 
  }
}