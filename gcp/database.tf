# Secret for PostgreSQL password
resource "kubernetes_secret" "postgresql" {
  metadata {
    name = "postgresql"
  }
  data = {
    # Replace "yourpassword" with your actual password
    # The value should be base64 encoded
    POSTGRES_PASSWORD = base64encode(var.password)
  }
  type = "Opaque"
}

# ConfigMap for PostgreSQL configuration
resource "kubernetes_config_map" "postgresql" {
  metadata {
    name = "postgresql"
  }
  data = {
    # Add your configuration data here
    POSTGRES_DB   = "mydatabase"
    POSTGRES_HOST = "localhost"
    POSTGRES_USER = "admin"
  }
}

# StatefulSet for PostgreSQL
resource "kubernetes_stateful_set" "postgresql" {
  metadata {
    name = "postgresql"
  }
  spec {
    service_name = kubernetes_service.postgresql.metadata[0].name
    replicas     = 3
    selector {
      match_labels = {
        app = "postgresql"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgresql"
        }
      }
      spec {
        container {
          name  = "postgresql"
          image = "postgres:alpine3.19"
          env {
            name = "POSTGRES_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgresql.metadata[0].name
                key  = "POSTGRES_HOST"
              }
            }
          }
          env {
            name = "POSTGRES_USER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgresql.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgresql.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
          env {
            name = "POSTGRES_DB"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgresql.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }
          port {
            container_port = 5432
          }
          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = "postgresql-data"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "postgresql-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "10Gi"
          }
        }
        storage_class_name = "standard"
      }
    }
  }
}

# Service for PostgreSQL
resource "kubernetes_service" "postgresql" {
  metadata {
    name = "postgresql"
  }
  spec {
    selector = {
      app = "postgresql"
    }
    port {
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }
    type = "ClusterIP"
  }
}
