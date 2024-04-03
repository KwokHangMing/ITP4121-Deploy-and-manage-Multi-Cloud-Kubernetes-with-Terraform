terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.92.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.26.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.primary.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.primary.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.primary.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.primary.kube_config.0.cluster_ca_certificate)
}
