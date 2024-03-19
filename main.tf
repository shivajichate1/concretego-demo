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

