resource "azurerm_kubernetes_cluster" "primary" {
  name                = "${var.name}-aks"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  dns_prefix          = "${var.name}aks"

  default_node_pool {
    name                = var.name
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    vm_size             = "Standard_D2_v2"
  }
  service_principal {
    client_id     = azuread_application.app.client_id
    client_secret = azuread_service_principal_password.app.value
  }
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.app.id
  }
}

resource "kubernetes_service_v1" "app" {
  metadata {
    name = "app"
  }
  spec {
    selector = {
      app = "app"
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_ingress_v1" "app" {
  metadata {
    name = "app-ingress"
  }
  spec {
    rule {
      host = var.domain_name
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_v1" "app" {
  metadata {
    name = "app"
  }
  spec {
    capacity = {
      storage = "100Gi"
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "managed"
    persistent_volume_source {
      azure_disk {
        disk_name     = azurerm_managed_disk.app.name
        caching_mode  = "None"
        data_disk_uri = azurerm_managed_disk.app.id
        kind          = "Managed"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "app" {
  metadata {
    name      = "app"
    namespace = "default"
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "managed"
    resources {
      requests = {
        storage = "100Gi"
      }
    }
    volume_name = kubernetes_persistent_volume_v1.app.metadata[0].name
  }
}


resource "kubernetes_deployment_v1" "app" {
  metadata {
    name = "app"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "app"
      }
    }
    template {
      metadata {
        labels = {
          app = "app"
        }
      }
      spec {
        container {
          name  = "app"
          image = var.image_url
          resources {
            limits = {
              cpu    = "1"
              memory = "2Gi"
            }
            requests = {
              cpu    = "50m"
              memory = "50Mi"
            }
          }
          volume_mount {
            mount_path = "/app"
            name       = "app"
          }
          port {
            container_port = 80
          }
        }
        volume {
          name = "app"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.app.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "app" {
  metadata {
    name = "app"
  }
  spec {
    max_replicas = 10
    min_replicas = 3
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.app.metadata[0].name
    }
    target_cpu_utilization_percentage = 50
  }
}

