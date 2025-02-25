
# Select the Azure Resource Group dynamically
data "azurerm_resource_group" "selected" {
  name = lookup(var.resource_group_map, var.env, "concretego-api")
}



# Azure Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "frontdoor_profile" {
  name                = "${var.env}-api-frontdoor"
  resource_group_name = data.azurerm_resource_group.selected.name
  sku_name            = var.frontdoor_sku_map[var.env]
}


# Enable system-assigned identity for the CDN Front Door profile

resource "azurerm_resource_group_template_deployment" "enable_identity" {
  name                = "EnableFrontdoorIdentityDeployment"
  resource_group_name = data.azurerm_resource_group.selected.name
  deployment_mode     = "Incremental"

  template_content = file("${path.module}/arm_templates/enable_identity.json")

  parameters_content = jsonencode({
    frontDoorProfileName = {
      value = azurerm_cdn_frontdoor_profile.frontdoor_profile.name
    }
    skuName = {
      value = var.frontdoor_sku_map[var.env]  # SKU dynamically from Terraform variable
    }
  })

  timeouts {
    create = "1h"
    update = "1h"
  }

  
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [template_content]
  }

  depends_on = [azurerm_cdn_frontdoor_profile.frontdoor_profile]
  
}


# Azure Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "endpoints" {
  count = var.env == "prod" ? length(var.prod_regions) : 1

  name = var.env == "prod" ? "${var.prod_regions[count.index]}-api" : "${var.env}-api"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id

  depends_on = [azurerm_cdn_frontdoor_profile.frontdoor_profile]

}


# Azure Front Door Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "origin_groups" {
  count = var.env == "prod" ? length(var.prod_regions) : 1

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id
  name                     = var.env == "prod" ? "${var.prod_regions[count.index]}-api-origin-group" : "${var.env}-api-origin-group"

  health_probe {
    interval_in_seconds = 5
    path                = "/api/test"
    protocol            = "Https"
    request_type        = "GET"
  }
  load_balancing {
    additional_latency_in_milliseconds = 10
  }

  depends_on = [azurerm_cdn_frontdoor_profile.frontdoor_profile]


}



# Azure Front Door Origins (Applies priority only for Production)
resource "azurerm_cdn_frontdoor_origin" "origins" {
  count = var.env == "prod" ? length(var.prod_regions) * 4 : 1  # 4 origins per region in production, 1 for dev/staging

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_groups[
    var.env == "prod" ? floor(count.index / 4) : 0
  ].id

  certificate_name_check_enabled = true
  host_name                      = var.env == "prod" ? var.origin_map[var.priority_map[var.prod_regions[floor(count.index / 4)]][count.index % 4]] : var.origin_map[var.env]
  name                           = var.env == "prod" ? var.priority_map[var.prod_regions[floor(count.index / 4)]][count.index % 4] : var.env
  origin_host_header             = var.env == "prod" ? var.origin_map[var.priority_map[var.prod_regions[floor(count.index / 4)]][count.index % 4]] : var.origin_map[var.env]
  enabled                        = true

  # Dynamic priority assignment
  priority = var.env == "prod" ? (count.index % 4) + 1 : null

  weight = 1000

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin_group.origin_groups,
    azurerm_cdn_frontdoor_endpoint.endpoints
  ]
}



# Fetch existing Key Vault details using a data block
data "azurerm_key_vault" "concretego_keyvault" {
  name                = "concretego-keyvault"
  resource_group_name = "concretego"
}


# Fetch the current client configuration to get tenant ID
data "azurerm_client_config" "current" {}

#service principal

resource "time_sleep" "wait_for_identity" {
  depends_on      = [azurerm_resource_group_template_deployment.enable_identity]
  create_duration = "60s" # Waits for 60 seconds
}

data "azuread_service_principal" "frontdoor_identity" {
  display_name = azurerm_cdn_frontdoor_profile.frontdoor_profile.name
  depends_on   = [azurerm_cdn_frontdoor_profile.frontdoor_profile,azurerm_resource_group_template_deployment.enable_identity]
}

output "frontdoor_identity_object_id" {
  value = data.azuread_service_principal.frontdoor_identity.object_id
}

resource "azurerm_key_vault_access_policy" "frontdoor_access_policy" {
  key_vault_id = data.azurerm_key_vault.concretego_keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  object_id = data.azuread_service_principal.frontdoor_identity.object_id

  secret_permissions  = ["Get", "List"]

  lifecycle {
    ignore_changes = [object_id, key_permissions, certificate_permissions, storage_permissions]
  }

  depends_on = [ azurerm_resource_group_template_deployment.enable_identity ]
}


resource "azurerm_cdn_frontdoor_secret" "sysdyne_certificate" {
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id
  name                     = "cgsysdynecloud"
  secret {
    customer_certificate {
      key_vault_certificate_id = "https://concretego-keyvault.vault.azure.net/secrets/cg-sysdyne-cloud-sslc0b7f58a-8aef-4e0f-967c-37c8897ec223"
    }
  }

  lifecycle {
    ignore_changes = [
      secret[0].customer_certificate[0].key_vault_certificate_id,
      secret[0].customer_certificate[0].subject_alternative_names
    ]
  }

  depends_on = [
    azurerm_key_vault_access_policy.frontdoor_access_policy, azurerm_cdn_frontdoor_profile.frontdoor_profile, azurerm_resource_group_template_deployment.enable_identity
  ]

}



# Create a custom domain for each subdomain
resource "azurerm_cdn_frontdoor_custom_domain" "cgsysdynecloud_custom_domain" {
  count = var.env == "prod" ? length(var.prod_regions) : 1

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id
  host_name                = var.env == "prod" ? "${var.prod_regions[count.index]}-api.cg.sysdyne.cloud" : "${var.env}-api.cg.sysdyne.cloud"
  name                     = var.env == "prod" ? "custom-${var.prod_regions[count.index]}" : "custom-${var.env}" 

  tls {
    certificate_type       = "CustomerCertificate"
    cdn_frontdoor_secret_id = azurerm_cdn_frontdoor_secret.sysdyne_certificate.id
  }

  # lifecycle {
  #   create_before_destroy = true  
  # }
  

  depends_on = [
    azurerm_cdn_frontdoor_profile.frontdoor_profile,
    azurerm_cdn_frontdoor_secret.sysdyne_certificate
  ]
}


# Route mapping: Assign correct domain based on environment
resource "azurerm_cdn_frontdoor_route" "api_routes" {
  count = var.env == "prod" ? length(var.prod_regions) : 1

  name                            = var.env == "prod" ? "api-route-${var.prod_regions[count.index]}" : "${var.env}-route-dev"
  cdn_frontdoor_endpoint_id       = var.env == "prod" ? azurerm_cdn_frontdoor_endpoint.endpoints[count.index].id : azurerm_cdn_frontdoor_endpoint.endpoints[0].id
  cdn_frontdoor_origin_group_id   = var.env == "prod" ? azurerm_cdn_frontdoor_origin_group.origin_groups[count.index].id : azurerm_cdn_frontdoor_origin_group.origin_groups[0].id
  cdn_frontdoor_origin_ids        = var.env == "prod" ? [azurerm_cdn_frontdoor_origin.origins[count.index].id] : [azurerm_cdn_frontdoor_origin.origins[0].id]
  
  # FIXED: Assign the correct custom domain per region
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.cgsysdynecloud_custom_domain[count.index].id]

  link_to_default_domain = false
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  depends_on = [
    azurerm_cdn_frontdoor_profile.frontdoor_profile,
    azurerm_cdn_frontdoor_endpoint.endpoints,
    azurerm_cdn_frontdoor_origin_group.origin_groups,
    azurerm_cdn_frontdoor_origin.origins,
    azurerm_cdn_frontdoor_custom_domain.cgsysdynecloud_custom_domain
  ]
}
