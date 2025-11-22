resource "google_compute_network" "hcl_hackathon_vpc_network" {
  name                                      = "${var.vpc_network_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private-subnetwork" {
  name          = "private-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  private_ip_google_access = true
  network       = google_compute_network.hcl_hackathon_vpc_network.name
}

resource "google_compute_subnetwork" "public-subnetwork" {
  name          = "public-subnetwork"
  ip_cidr_range = "10.7.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.hcl_hackathon_vpc_network.name
}