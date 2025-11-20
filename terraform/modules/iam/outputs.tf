output "gke_nodes_service_account_email" {
  description = "Email of the GKE nodes service account"
  value       = google_service_account.gke_nodes.email
}

output "cicd_service_account_email" {
  description = "Email of the CI/CD service account"
  value       = google_service_account.cicd.email
}

output "workload_identity_service_account_email" {
  description = "Email of the workload identity service account"
  value       = google_service_account.workload_identity.email
}

output "workload_identity_service_account_name" {
  description = "Resource name of the workload identity service account"
  value       = google_service_account.workload_identity.name
}
