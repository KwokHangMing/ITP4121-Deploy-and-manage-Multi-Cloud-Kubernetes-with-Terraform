resource "azurerm_kubernetes_cluster" "primary" {
  name                = "${var.name}-aks"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  dns_prefix          = "${var.name}aks"

  default_node_pool {
    name       = "${var.name}"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "kubernetes_service" "app" {
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
      target_port = 8080
    }
    type             = "LoadBalancer"
    session_affinity = "ClientIP"
    load_balancer_ip = azurerm_kubernetes_cluster.primary.http_application_routing_zone_name
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "app"
  }
  spec {
    replicas = 3
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
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          volume_mount {
            mount_path = "/app"
            name       = "app-volume"
          }
          port {
            container_port = 8080
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
          }
        }
        volume {
          name = "app-volume"
          # persistent_volume_claim {
          #   claim_name = kubernetes_persistent_volume_claim.primary.metadata[0].name
          # }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "app" {
  metadata {
    name = "app"
  }
  spec {
    max_replicas = 10
    min_replicas = 3
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }
    target_cpu_utilization_percentage = 50
  }
}

