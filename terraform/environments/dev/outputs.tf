output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_location" {
  description = "GKE cluster location"
  value       = module.gke.cluster_location
}

output "vpc_name" {
  description = "VPC name"
  value       = module.vpc.vpc_name
}

output "terraform_state_bucket" {
  description = "Terraform state bucket name"
  value       = module.storage.terraform_state_bucket
}

output "docker_repository" {
  description = "Docker repository name"
  value       = module.storage.docker_repository_name
}

output "cicd_service_account" {
  description = "CI/CD service account email"
  value       = module.iam.cicd_service_account_email
}
