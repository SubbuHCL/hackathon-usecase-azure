// File: modules/gke/main.tf  (optimized for faster single-zone creation)

resource "google_container_cluster" "primary" {
  name     = "${var.project_prefix}-gke-${var.environment}"
  # Force single-zone to speed up node provisioning
  location = "${var.region}-a"
  project  = var.project_id
  deletion_protection = false

  # Remove default node pool so Terraform only manages separately-created node pools.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.vpc_name
  subnetwork = var.subnet_name

  # Enabling Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  network_policy {
    enabled = true
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  resource_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  # IMPORTANT: no node_pool block here — we remove the default pool and manage node pools separately
}

# Separately managed node pool (single-zone: faster)
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.project_prefix}-node-pool-${var.environment}"
  # Match cluster single-zone location to avoid multi-zone provisioning delays
  location   = "${var.region}-a"
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = var.node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"

    service_account = var.service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }

    tags = ["gke-node", "${var.project_prefix}-gke-${var.environment}"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Ensure node pool is created after cluster exists
  depends_on = [google_container_cluster.primary]
}
