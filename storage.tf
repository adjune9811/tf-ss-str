# This file is a reference pointer.
# The actual Terraform configuration lives in: terraform/storage/
#
# To deploy via Azure DevOps:
#   Pipeline: pipelines/deploy-storage.yml
#
# To deploy locally:
#   cd terraform/storage
#   terraform init
#   terraform plan -var="environment=dev"
#   terraform apply -var="environment=dev"
