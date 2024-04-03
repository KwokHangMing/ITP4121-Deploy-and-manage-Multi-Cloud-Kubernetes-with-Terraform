resource "google_compute_network" "test" {
  name                    = "itp4121-vpc-network"
  auto_create_subnetworks = false
}

resource "google_compute_address" "default" {
  name = "tf-gke-k8s"
}

resource "google_compute_disk" "primary" {
  name = "primary"
  type = "pd-standard"
  size = 100
  zone = var.zone
}

resource "google_compute_firewall" "basic" {
  name    = "allow-http"
  network = google_compute_network.test.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_tags = ["web"]
}

resource "google_compute_subnetwork" "subnet1" {
  name          = "${var.project}-itp4121-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.test.id

  secondary_ip_range {
    range_name    = "${var.project}-my-pods-range"
    ip_cidr_range = "192.168.10.0/24"
  }

  secondary_ip_range {
    range_name    = "${var.project}-my-services-range"
    ip_cidr_range = "192.168.11.0/24"
  }
}

resource "google_compute_network_endpoint_group" "app" {
  name         = "${var.project}-app-endpoint-group"
  network      = google_compute_network.test.self_link
  subnetwork   = google_compute_subnetwork.subnet1.self_link
  default_port = "80"
  zone         = var.zone
}

resource "google_compute_network_endpoint_group" "postgres" {
  name         = "${var.project}-postgres-endpoint-group"
  network      = google_compute_network.test.self_link
  subnetwork   = google_compute_subnetwork.subnet1.self_link
  default_port = "5432"
  zone         = var.zone
}
