resource "google_container_cluster" "primary" {
  name     = "${var.gke_cluster_name}"
  location = "us-central1"
  network  = "${var.vpc_network_name}"
  subnetwork = "public-subnetwork"
  remove_default_node_pool = true
  deletion_protection = false
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "${var.gke_node_pool_name}"
  location   = "us-central1"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-micro"
  }
}