variable "resource_group_name" {
  type    = string
  default = "rg-devops-demo-aks"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "prefix" {
  type    = string
  default = "devdemo"
}

variable "acr_name" {
  description = "ACR name — no hyphens, globally unique, 5-50 chars"
  type        = string
  default     = "acrdevdemo001"
}

variable "environment" {
  type    = string
  default = "dev"
}
