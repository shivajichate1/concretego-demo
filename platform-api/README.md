# API

##local




For dev environment:
terraform init -backend-config="backend-configs/dev.backend.tfvars"     #  terraform init  -reconfigure
                            
terraform plan -var="env=dev"
terraform apply -var="env=dev"        # auto approvel use terraform apply -auto-approve -var="env=dev"  


For e2e environment:
terraform init -backend-config="backend-configs/e2e.backend.tfvars"     #  terraform init  -reconfigure
terraform plan -var="env=e2e"
terraform apply -var="env=e2e"        # auto approvel use terraform apply -auto-approve -var="env=e2e"  


# force state
terraform apply -var-file="e2e.tfvars" -replace="azurerm_api_management.apim_custom_domain"


For ga environment:
terraform init -backend-config="backend-configs/ga.backend.tfvars"     #  terraform init  -reconfigure
terraform plan -var="env=ga"
terraform apply -var="env=ga"        # auto approvel use terraform apply -auto-approve -var="env=ga"  


For prod environment:

terraform init -backend-config="backend-configs/prod.backend.tfvars"     #  terraform init  -reconfigure
terraform plan -var="env=prod"
terraform apply -var="env=prod"        # auto approvel use terraform apply -auto-approve -var="env=prod"  




