# IAM Module - Service Accounts and Roles

# Service Account for GKE Nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.project_prefix}-gke-nodes-${var.environment}"
  display_name = "GKE Nodes Service Account - ${var.environment}"
  project      = var.project_id
}

# IAM roles for GKE nodes
resource "google_project_iam_member" "gke_node_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_node_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_node_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_node_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Service Account for CI/CD (GitHub Actions)
resource "google_service_account" "cicd" {
  account_id   = "${var.project_prefix}-cicd-${var.environment}"
  display_name = "CI/CD Service Account - ${var.environment}"
  project      = var.project_id
}

# IAM roles for CI/CD
resource "google_project_iam_member" "cicd_gcr_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.cicd.email}"
}

resource "google_project_iam_member" "cicd_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.cicd.email}"
}

resource "google_project_iam_member" "cicd_artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cicd.email}"
}

# Workload Identity binding for applications
resource "google_service_account" "workload_identity" {
  account_id   = "${var.project_prefix}-workload-${var.environment}"
  display_name = "Workload Identity Service Account - ${var.environment}"
  project      = var.project_id
}
# NOTE: workload identity binding moved to environment root so it can depend
# on the GKE cluster creation. Creating the binding before the GKE cluster
# exists can cause "Identity Pool does not exist" errors because the
# workload identity pool is established during cluster creation.
# Monitoring and logging permissions for workload
resource "google_project_iam_member" "workload_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workload_identity.email}"
}

resource "google_project_iam_member" "workload_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.workload_identity.email}"
}
