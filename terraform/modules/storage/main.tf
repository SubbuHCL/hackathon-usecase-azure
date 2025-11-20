# Storage Module - GCS Bucket for Terraform State

resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_prefix}-tfstate-${var.environment}-${var.project_id}-${random_id.bucket_suffix.hex}"
  location      = var.region
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "terraform-state"
    managed_by  = "terraform"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "${var.project_prefix}-docker-${var.environment}"
  description   = "Docker repository for ${var.environment} environment"
  format        = "DOCKER"
  project       = var.project_id

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
