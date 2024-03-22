
resource "azurerm_resource_group" "concretego-demo" {
  tags     = merge(var.tags, {})
  name     = "concretego-${var.prefix}"
  location = var.location
}


resource "azurerm_service_plan" "concretego-ASP" {
  tags                = merge(var.tags, {})
  sku_name            = var.app_service_plans["cgapps_asp"].sku_name
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
  https_only          = true

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
    use_32_bit_worker = false   # Setting to false enables 64-bit platform
    application_stack {
      dotnet_version = "v6.0"
      current_stack  = "dotnet"
    }
    http2_enabled            = true  # This is required for session affinity
    websockets_enabled       = true   # Enable Web Sockets
    ftps_state               = "Disabled"  # Disable FTPS

  }
}

resource "azurerm_template_deployment" "concretego_IISManager" {
  name                = "IISManagerExtensionDeployment"
  resource_group_name = azurerm_resource_group.concretego-demo.name
  deployment_mode     = "Incremental"
  template_body       = file("${path.module}/arm_templates/iis_manager_extension.json")

  parameters = {
    siteName = azurerm_windows_web_app.concretego.name
  }
}


resource "azurerm_windows_web_app" "concretego-api" {
  tags                = merge(var.tags, {})
  service_plan_id     = azurerm_service_plan.concretego-ASP.id
  resource_group_name = azurerm_resource_group.concretego-demo.name
  name                = "concretego-api-${var.prefix}"
  location            = var.location
  https_only          = true
  client_affinity_enabled = true  # Session Affinity

  app_settings = {
    ASPNETCORE_ENVIRONMENT = "${var.env}"
  }

  site_config {
    always_on          = true
    use_32_bit_worker = false   # Setting to false enables 64-bit platform
    application_stack {
      dotnet_version = "v6.0"
      current_stack  = "dotnet"
    }
    http2_enabled            = true  # This is required for session affinity
    websockets_enabled       = true   # Enable Web Sockets
    ftps_state               = "Disabled"  # Disable FTPS
  }
}

resource "azurerm_redis_cache" "concretego-redis_cache" {
  tags                = merge(var.tags, {})
  sku_name            = var.redis_caches["concretego_redis_cache"].sku_name
  resource_group_name = azurerm_resource_group.concretego-demo.name
  name                = "concretego-${var.prefix}"
  location            = var.location
  family              = var.redis_caches["concretego_redis_cache"].family
  capacity            = var.redis_caches["concretego_redis_cache"].capacity

  redis_configuration {
    maxmemory_reserved = var.redis_caches["concretego_redis_cache"].maxmemory_reserved
    maxmemory_policy   = var.redis_caches["concretego_redis_cache"].maxmemory_policy
  }
}

resource "azurerm_storage_account" "concretego-storage_account" {
  tags                     = merge(var.tags, {})
  resource_group_name      = azurerm_resource_group.concretego-demo.name
  name                     = "concretego${var.prefix}"
  location                 = var.location
  account_tier             = var.storage_accounts["concretego_storage_account"].account_tier
  account_replication_type = var.storage_accounts["concretego_storage_account"].account_replication_type
  account_kind             = var.storage_accounts["concretego_storage_account"].account_kind
  access_tier              = var.storage_accounts["concretego_storage_account"].access_tier
}

resource "azurerm_resource_group" "webcrete" {
  tags     = merge(var.tags, {})
  name     = "webcrete${var.prefix}"
  location = var.location
}

resource "azurerm_service_plan" "concretego-funcation-service_plan" {
  tags                = merge(var.tags, {})
  sku_name            = var.app_service_plans["cgfuncation_asp"].sku_name
  resource_group_name = azurerm_resource_group.webcrete.name
  os_type             = "Windows"
  name                = "concretego-${var.prefix}-Funcation-ASP"
  location            = var.location
}

resource "azurerm_storage_account" "eventhub-storage_account" {
  tags                     = merge(var.tags, {})
  resource_group_name      = azurerm_resource_group.webcrete.name
  name                     = "eventhubcnewcg${var.prefix}"
  location                 = var.location
  account_tier             = var.storage_accounts["eventhub_storage_account"].account_tier
  account_replication_type = var.storage_accounts["eventhub_storage_account"].account_replication_type
  account_kind             = var.storage_accounts["eventhub_storage_account"].account_kind
  access_tier              = var.storage_accounts["eventhub_storage_account"].access_tier
}

resource "azurerm_windows_function_app" "eventhub-function-app" {
  tags                       = merge(var.tags, {})
  storage_account_name       = azurerm_storage_account.eventhub-storage_account.name
  storage_account_access_key = azurerm_storage_account.eventhub-storage_account.primary_access_key
  service_plan_id            = azurerm_service_plan.concretego-funcation-service_plan.id
  resource_group_name        = azurerm_resource_group.webcrete.name
  name                       = "eventhubcgnew-${var.prefix}"
  location                   = var.location

  site_config {
    always_on = true
  }
}

