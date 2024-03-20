resource "azurerm_resource_group" "concretego-demo" {
  tags     = merge(var.tags, {})
  name     = "concretego-${var.prefix}"
  location = var.location
}

resource "azurerm_service_plan" "concretego-ASP" {
  tags                = merge(var.tags, {})
  sku_name            = "B1"
  resource_group_name = azurerm_resource_group.concretego-demo.name
  os_type             = "Windows"
  name                = "concretego-${var.prefix}"
  location            = var.location
}

resource "azurerm_windows_web_app" "concretego" {
  tags                = merge(var.tags, {})
  service_plan_id     = azurerm_service_plan.concretego-ASP.id
  resource_group_name = azurerm_resource_group.concretego-demo.name
  name                = "concretego-${var.prefix}"
  location            = var.location

  app_settings = {
    RedisConnectionString = azurerm_redis_cache.concretego-redis_cache.primary_access_key
  }

  connection_string {
    value = azurerm_redis_cache.concretego-redis_cache.primary_access_key
    type  = "RedisCache"
    name  = "RedisConnectionString"
  }

  site_config {
    always_on = true
  }
}

resource "azurerm_windows_web_app" "concretego-api" {
  tags                = merge(var.tags, {})
  service_plan_id     = azurerm_service_plan.concretego-ASP.id
  resource_group_name = azurerm_resource_group.concretego-demo.name
  name                = "concretego-api-${var.prefix}"
  location            = var.location
  https_only          = true

  app_settings = {
    ASPNETCORE_ENVIRONMENT = "Staging"
  }

  site_config {
    websockets_enabled = true
    always_on          = true
  }
}

resource "azurerm_redis_cache" "concretego-redis_cache" {
  tags                = merge(var.tags, {})
  sku_name            = "Standard"
  resource_group_name = azurerm_resource_group.concretego-demo.name
  name                = "concretego-${var.prefix}"
  location            = var.location
  family              = "C"
  capacity            = 0

  redis_configuration {
    maxmemory_reserved = 35
    maxmemory_policy   = "volatile-lru"
  }
}

resource "azurerm_storage_account" "concretego-storage_account" {
  tags                     = merge(var.tags, {})
  resource_group_name      = azurerm_resource_group.concretego-demo.name
  name                     = "concretego${var.prefix}"
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
}

resource "azurerm_resource_group" "webcrete" {
  tags     = merge(var.tags, {})
  name     = "webcrete${var.prefix}"
  location = var.location
}

resource "azurerm_service_plan" "concretego-funcation-service_plan" {
  tags                = merge(var.tags, {})
  sku_name            = "B1"
  resource_group_name = azurerm_resource_group.webcrete.name
  os_type             = "Windows"
  name                = "concretego-${var.prefix}-Funcation-ASP"
  location            = var.location
}

resource "azurerm_storage_account" "eventhub-storage_account" {
  tags                     = merge(var.tags, {})
  resource_group_name      = azurerm_resource_group.webcrete.name
  name                     = "eventhubcg${var.prefix}"
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
}

resource "azurerm_windows_function_app" "eventhub-function-app" {
  tags                       = merge(var.tags, {})
  storage_account_name       = azurerm_storage_account.eventhub-storage_account.name
  storage_account_access_key = azurerm_storage_account.eventhub-storage_account.primary_access_key
  service_plan_id            = azurerm_service_plan.concretego-funcation-service_plan.id
  resource_group_name        = azurerm_resource_group.webcrete.name
  name                       = "eventhubcg-${var.prefix}"
  location                   = var.location

  site_config {
    always_on = true
  }
}

