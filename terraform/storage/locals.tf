locals {
  env_short = {
    dev     = "dev"
    staging = "stg"
    prod    = "prd"
  }

  # Storage account name rules: 3-24 chars, lowercase + numbers only, globally unique.
  # We reserve the last 1 char for the count index digit (0-9).
  # e.g. project="devops-demo", env="dev" → prefix = "stdevopsdemodev" → accounts: stdevopsdemodev0, stdevopsdemodev1
  storage_name_prefix = lower(
    substr(
      replace("st${var.project}${local.env_short[var.environment]}", "-", ""),
      0, 23   # max 23 so appending count.index (1 digit) stays within 24-char limit
    )
  )

  # Flatten (account index × container name) into a single for_each-compatible map.
  # range(N) produces [0, 1, ..., N-1] — one entry per storage account.
  #
  # Example: storage_account_count=2, containers=["uploads","logs"]
  #   {
  #     "0-uploads" = { account_index=0, container_name="uploads" }
  #     "0-logs"    = { account_index=0, container_name="logs"    }
  #     "1-uploads" = { account_index=1, container_name="uploads" }
  #     "1-logs"    = { account_index=1, container_name="logs"    }
  #   }
  container_map = merge([
    for idx in range(var.storage_account_count) : {
      for c in var.containers :
      "${idx}-${c}" => {
        account_index  = idx
        container_name = c
      }
    }
  ]...)

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    DeployedBy  = "AzureDevOps"
  }
}
