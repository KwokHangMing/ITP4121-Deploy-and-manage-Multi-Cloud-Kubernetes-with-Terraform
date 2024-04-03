output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "static_ip_address" {
  value = google_compute_address.default.address
}

output "load-balancer-ip" {
  value = google_compute_address.default.address
}