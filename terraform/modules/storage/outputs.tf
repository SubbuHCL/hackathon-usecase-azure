output "terraform_state_bucket" {
  description = "Name of the Terraform state bucket"
  value       = google_storage_bucket.terraform_state.name
}

output "docker_repository_id" {
  description = "ID of the Docker repository"
  value       = google_artifact_registry_repository.docker_repo.id
}

output "docker_repository_name" {
  description = "Name of the Docker repository"
  value       = google_artifact_registry_repository.docker_repo.name
}
