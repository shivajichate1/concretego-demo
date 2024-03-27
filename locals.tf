locals {
  default_custom_domains_concretego = {
    e2e = ["e2e.concretego.com", "e2e.cg.sysdyne.cloud"]
    production = ["*.concretego.com", "*.cg.sysdyne.cloud", "cg.sysdyne.cloud", "concretego.com"]
  }
  
  default_custom_domains_concretego_api = {
    e2e = ["api-e2e.concretego.com"]
    production = ["*.concretego.com"]
  }
}