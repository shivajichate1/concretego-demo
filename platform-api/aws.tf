

# AWS Route 53 DNS Record Configuration
resource "aws_route53_record" "dns_record" {
  count = var.env == "prod" ? length(var.prod_regions) : 1

  zone_id = var.aws_route53_zone_id
  name    = var.env == "prod" ? "${var.prod_regions[count.index]}-api.cg.sysdyne.cloud" : "${var.env}-api.cg.sysdyne.cloud"
  type    = "CNAME"
  ttl     = 300

  # Ensure correct mapping of Front Door endpoints to DNS records
  records = [azurerm_cdn_frontdoor_endpoint.endpoints[count.index].host_name]

  lifecycle {
    ignore_changes = [records]
  }

  depends_on = [
    azurerm_cdn_frontdoor_endpoint.endpoints
  ]

}


