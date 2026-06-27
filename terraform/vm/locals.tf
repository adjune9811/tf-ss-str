locals {
  common_tags = {
    Environment = var.environment
    Project     = "azure-devops-demo"
    ManagedBy   = "Terraform"
  }
}
