
# resource "azurerm_resource_group" "concretego-demo" {
#   tags     = merge(var.tags, {})
#   name     = "concretego-${var.suffix}"
#   location = var.location
# }


resource "azurerm_service_plan" "concretego-ASP" {
  tags                = merge(var.tags, {})
  sku_name            = var.app_service_plans["cgapps_asp"].sku_name
  resource_group_name = "concretego-${var.rg}"
  os_type             = "Windows"
  name                = "concretego-${var.suffix}"
  location            = var.location
}

resource "azurerm_windows_web_app" "concretego" {
  tags                = merge(var.tags, {})
  service_plan_id     = azurerm_service_plan.concretego-ASP.id
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-${var.suffix}"
  location            = var.location
  https_only          = true

  app_settings = {
    RedisConnectionString = azurerm_redis_cache.concretego-redis_cache.primary_connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~2"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.concretego-application-insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.concretego-application-insights.connection_string
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

resource "azurerm_application_insights" "concretego-application-insights" {
  tags                = merge(var.tags, {})
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-${var.suffix}"
  location            = var.location
  application_type    = "web"
}

resource "azurerm_application_insights" "concretego-api-application-insights" {
  tags                = merge(var.tags, {})
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-api-${var.suffix}"
  location            = var.location
  application_type    = "web"
}



resource "azurerm_template_deployment" "concretego_IISManager" {
  name                = "IISManagerExtensionDeployment"
  resource_group_name = "concretego-${var.rg}"
  deployment_mode     = "Incremental"
  template_body       = file("${path.module}/arm_templates/iis_manager_extension.json")

  parameters = {
    siteName = azurerm_windows_web_app.concretego.name
  }
}


resource "azurerm_windows_web_app" "concretego-api" {
  tags                = merge(var.tags, {})
  service_plan_id     = azurerm_service_plan.concretego-ASP.id
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-api-${var.suffix}"
  location            = var.location
  https_only          = true
  client_affinity_enabled = true  # Session Affinity

  app_settings = {
    ASPNETCORE_ENVIRONMENT = "${var.env}"
    ApplicationInsightsAgent_EXTENSION_VERSION = "~2"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.concretego-api-application-insights.instrumentation_key    
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.concretego-api-application-insights.connection_string
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
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-${var.suffix}"
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
  resource_group_name      = "concretego-${var.rg}"
  name                     = "concretego${var.suffix}"
  location                 = var.location
  account_tier             = var.storage_accounts["concretego_storage_account"].account_tier
  account_replication_type = var.storage_accounts["concretego_storage_account"].account_replication_type
  account_kind             = var.storage_accounts["concretego_storage_account"].account_kind
  access_tier              = var.storage_accounts["concretego_storage_account"].access_tier
}

# Custom domain bindings for concretego Azure Web App
resource "azurerm_app_service_custom_hostname_binding" "concretego_custom_domain" {
  for_each            = toset(local.default_custom_domains_concretego[var.env])
  hostname            = each.value
  app_service_name    = azurerm_windows_web_app.concretego.name
  resource_group_name = azurerm_windows_web_app.concretego.resource_group_name
}

# Custom domain bindings for concretego-api Azure Web App
resource "azurerm_app_service_custom_hostname_binding" "concretego_api_custom_domain" {
  for_each            = toset(local.default_custom_domains_concretego_api[var.env])
  hostname            = each.value
  app_service_name    = azurerm_windows_web_app.concretego-api.name
  resource_group_name = azurerm_windows_web_app.concretego-api.resource_group_name
}


# Define AWS Route 53 record resources for concretego Azure Web App (CNAME)
resource "aws_route53_record" "concretego_cname_records" {
  zone_id   = var.concretego_zone_id
  name      = "${var.env}.concretego.com"
  type      = "CNAME"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego.default_hostname]
}

resource "aws_route53_record" "concretego_sysdyne_cname_records" {
  zone_id   = var.cg_sysdyne_cloud_zone_id
  name      = "${var.env}.cg.sysdyne.cloud"
  type      = "CNAME"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego.default_hostname]
}

# Define AWS Route 53 record resources for concretego-api Azure Web App (CNAME)
resource "aws_route53_record" "concretego_api_cname_records" {
  for_each  = toset(local.default_custom_domains_concretego_api[var.env])
  zone_id   = var.concretego_zone_id
  name      = each.value
  type      = "CNAME"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego-api.default_hostname]
}


# Define AWS Route 53 record resources for concretego Azure Web App (TXT)
resource "aws_route53_record" "concretego_txt_records" {
  zone_id   = var.concretego_zone_id
  name      = "asuid.${var.env}.concretego.com"
  type      = "TXT"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego.custom_domain_verification_id]
}

# Define AWS Route 53 record resources for concretego-api Azure Web App (TXT)
resource "aws_route53_record" "concretego_api_txt_records" {
  for_each  = toset(local.default_custom_domains_concretego_api[var.env])
  zone_id   = var.concretego_zone_id  # Use the zone ID for concretego-api domain
  name      = "asuid.${each.value}"
  type      = "TXT"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego-api.custom_domain_verification_id]
}


# Define AWS Route 53 record resources for e2e.cg.sysdyne.cloud TXT record for concretego Azure Web App
resource "aws_route53_record" "concretego_sysdyne_txt_record" {
  zone_id   = var.cg_sysdyne_cloud_zone_id  # Use the zone ID for concretego domain
  name      = "asuid.${var.env}.cg.sysdyne.cloud"
  type      = "TXT"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego.custom_domain_verification_id]
}







# resource "azurerm_resource_group" "webcrete" {
#   tags     = merge(var.tags, {})
#   name     = "webcrete${var.suffix}"
#   location = var.location
# }

# resource "azurerm_service_plan" "concretego-funcation-service_plan" {
#   tags                = merge(var.tags, {})
#   sku_name            = var.app_service_plans["cgfuncation_asp"].sku_name
#   resource_group_name = azurerm_resource_group.webcrete.name
#   os_type             = "Windows"
#   name                = "concretego-${var.suffix}-Funcation-ASP"
#   location            = var.location
# }

# resource "azurerm_storage_account" "eventhub-storage_account" {
#   tags                     = merge(var.tags, {})
#   resource_group_name      = azurerm_resource_group.webcrete.name
#   name                     = "eventhubcnewcg${var.suffix}"
#   location                 = var.location
#   account_tier             = var.storage_accounts["eventhub_storage_account"].account_tier
#   account_replication_type = var.storage_accounts["eventhub_storage_account"].account_replication_type
#   account_kind             = var.storage_accounts["eventhub_storage_account"].account_kind
#   access_tier              = var.storage_accounts["eventhub_storage_account"].access_tier
# }

# resource "azurerm_windows_function_app" "eventhub-function-app" {
#   tags                       = merge(var.tags, {})
#   storage_account_name       = azurerm_storage_account.eventhub-storage_account.name
#   storage_account_access_key = azurerm_storage_account.eventhub-storage_account.primary_access_key
#   service_plan_id            = azurerm_service_plan.concretego-funcation-service_plan.id
#   resource_group_name        = azurerm_resource_group.webcrete.name
#   name                       = "eventhubcgnew-${var.suffix}"
#   location                   = var.location

#   site_config {
#     always_on = true
#   }
# }

