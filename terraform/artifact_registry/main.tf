resource "google_artifact_registry_repository" "hcl-hackathon-repo" {
  location      = "us-central1"
  repository_id = "hcl-hackathon-repo"
  description   = "hcl-hackathon-repo docker repository"
  format        = "DOCKER"
}