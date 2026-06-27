terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate001"
    container_name       = "tfstate"
    key                  = "aks/terraform.tfstate"   # separate state file from VM
  }
}

provider "azurerm" {
  features {}
}

# ─── Resource Group ───────────────────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ─── Azure Container Registry (ACR) ──────────────────────────────────────────
# CONCEPT: ACR is Azure's private Docker registry — like Docker Hub but private.
# Your pipeline pushes images here; AKS pulls from here.
resource "azurerm_container_registry" "main" {
  name                = var.acr_name          # globally unique, no hyphens
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"               # Basic is fine for learning; Standard adds geo-replication
  admin_enabled       = false                 # use managed identity instead of username/password

  tags = local.common_tags
}

# ─── AKS Cluster ─────────────────────────────────────────────────────────────
# CONCEPT: AKS = Azure Kubernetes Service.
# Azure manages the control plane (API server, etcd) for free.
# You only pay for the worker node VMs.
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.prefix            # becomes <prefix>.hcp.<region>.azmk8s.io

  # CONCEPT: default node pool
  # A node pool is a group of VMs (nodes) that run your containers.
  # 'system' mode means this pool runs Kubernetes system pods (CoreDNS, etc.)
  default_node_pool {
    name                = "system"
    node_count          = 1                   # 1 node for learning — use 3 for HA
    vm_size             = "Standard_B2s"      # 2 vCPU, 4 GB — minimum for AKS
    os_disk_size_gb     = 30
    type                = "VirtualMachineScaleSets"  # required for autoscaling
    enable_auto_scaling = false               # enable in prod: min_count=1, max_count=3
  }

  # CONCEPT: managed identity
  # AKS uses this identity to interact with Azure APIs (create load balancers, pull from ACR, etc.)
  # SystemAssigned = Azure creates and manages it automatically. Simpler than service principals.
  identity {
    type = "SystemAssigned"
  }

  # CONCEPT: network profile
  # Azure CNI gives each pod a real VNet IP (good for AKS integration).
  # Kubenet is simpler but has limitations with some Azure features.
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    load_balancer_sku = "standard"
  }

  tags = local.common_tags
}

# ─── Grant AKS permission to pull from ACR ────────────────────────────────────
# CONCEPT: Role assignment
# AKS needs the AcrPull role on ACR so it can pull images without credentials.
# This is the Azure RBAC way — no imagePullSecrets needed in Kubernetes.
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}
