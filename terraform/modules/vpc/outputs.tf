output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc.name
}

output "public_subnet_1_name" {
  description = "Name of public subnet 1"
  value       = google_compute_subnetwork.public_subnet_1.name
}

output "public_subnet_2_name" {
  description = "Name of public subnet 2"
  value       = google_compute_subnetwork.public_subnet_2.name
}

output "private_subnet_1_name" {
  description = "Name of private subnet 1"
  value       = google_compute_subnetwork.private_subnet_1.name
}

output "private_subnet_2_name" {
  description = "Name of private subnet 2"
  value       = google_compute_subnetwork.private_subnet_2.name
}

output "public_subnet_1_self_link" {
  description = "Self link of public subnet 1"
  value       = google_compute_subnetwork.public_subnet_1.self_link
}
