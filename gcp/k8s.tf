# google_client_config and kubernetes provider must be explicitly specified like the following.
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  client_certificate     = base64decode(google_container_cluster.primary.master_auth[0].client_certificate)
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  client_key             = base64decode(google_container_cluster.primary.master_auth[0].client_key)
  config_path            = "~/.kube/config"
}

# resource "kubernetes_namespace" "itp4121-namespace" {
#   metadata {
#     name = "my-terraform-namespace"
#   }
# }

data "google_container_cluster" "primary" {
  name     = google_container_cluster.primary.name
  location = google_container_cluster.primary.location
}

# data "local_file" "deployment" {
#   filename = "${path.module}/deployment.yaml"
# }

data "terraform_remote_state" "gke" {
  backend = "local"
  config = {
    path = "${path.module}/terraform.tfstate"
  }
}

# resource "kubernetes_manifest" "deployment" {
#   manifest = yamldecode(data.local_file.deployment.content)
# }

data "google_client_config" "default" {}

resource "google_service_account" "project" {
  account_id   = "itp4121-service-account"
  display_name = "ITP4121 Service Account"
}

resource "google_project_iam_member" "artifact_registry_policy" {
  project = var.project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.project.email}"
}

resource "google_logging_project_sink" "log" {
  name                   = "log"
  destination            = "storage.googleapis.com/${google_storage_bucket.logs-storage.name}"
  filter                 = "resource.type=\"k8s_container\""
  unique_writer_identity = true
}

resource "google_storage_bucket" "logs-storage" {
  name     = "${var.project}-logs"
  location = var.location
}

resource "google_storage_bucket_iam_member" "logs_storage_iam" {
  bucket = google_storage_bucket.logs-storage.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.project.email}"
}

resource "google_container_cluster" "primary" {
  name                = "${var.project}-primary"
  location            = var.location
  deletion_protection = false
  network             = google_compute_network.test.name
  subnetwork          = google_compute_subnetwork.subnet1.name
  logging_service     = "logging.googleapis.com/kubernetes"
  monitoring_service  = "monitoring.googleapis.com/kubernetes"

  node_pool {
    name = "terraform-node-pool"
    autoscaling {
      min_node_count = 2
      max_node_count = 4
    }
    node_config {
      service_account = google_service_account.project.email
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }
}

resource "kubernetes_persistent_volume" "app" {
  metadata {
    name = "app"
  }
  spec {
    capacity = {
      storage = "100Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      gce_persistent_disk {
        pd_name = google_compute_disk.primary.name
      }
    }
    storage_class_name = "standard-rwo" # Add this line
  }
}

resource "kubernetes_persistent_volume_claim" "app" {
  metadata {
    name = "app"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "100Gi"
      }
    }
    volume_name        = kubernetes_persistent_volume.app.metadata[0].name
    storage_class_name = "standard-rwo" # Add this line
  }
}

resource "kubernetes_deployment" "app" {
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
              memory = "500Mi"
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
            claim_name = kubernetes_persistent_volume_claim.app.metadata[0].name
          }
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
    min_replicas = 2
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "app"
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.app.spec[0].template[0].metadata[0].labels.app
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
    type             = "LoadBalancer"
    session_affinity = "ClientIP"
    load_balancer_ip = google_compute_address.default.address
  }
}

resource "kubernetes_ingress_v1" "primary" {
  metadata {
    name = "primary-ingress"
  }
  spec {
    rule {
      host = var.domain_name # Replace with your domain name
      http {
        path {
          path_type = "Prefix"
          path      = "/"
          backend {
            service {
              name = kubernetes_service.app.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}
