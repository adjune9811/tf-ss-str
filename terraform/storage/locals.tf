locals {
  # Storage account name rules: 3-24 chars, lowercase letters and numbers only, globally unique
  # Format: st + project (no hyphens) + env abbreviation
  env_short = {
    dev     = "dev"
    staging = "stg"
    prod    = "prd"
  }

  storage_account_name = lower(
    substr(
      replace("st${var.project}${local.env_short[var.environment]}", "-", ""),
      0, 24
    )
  )

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    DeployedBy  = "AzureDevOps"
  }
}
