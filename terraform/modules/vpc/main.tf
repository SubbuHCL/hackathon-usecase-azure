# VPC Module - Creates VPC with public and private subnets

resource "google_compute_network" "vpc" {
  name                    = "${var.project_prefix}-vpc-${var.environment}"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Public Subnet in Zone 1
resource "google_compute_subnetwork" "public_subnet_1" {
  name          = "${var.project_prefix}-public-subnet-1-${var.environment}"
  ip_cidr_range = var.public_subnet_cidr_1
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr_1
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr_1
  }
}

# Public Subnet in Zone 2
resource "google_compute_subnetwork" "public_subnet_2" {
  name          = "${var.project_prefix}-public-subnet-2-${var.environment}"
  ip_cidr_range = var.public_subnet_cidr_2
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr_2
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr_2
  }
}

# Private Subnet in Zone 1
resource "google_compute_subnetwork" "private_subnet_1" {
  name                     = "${var.project_prefix}-private-subnet-1-${var.environment}"
  ip_cidr_range            = var.private_subnet_cidr_1
  region                   = var.region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = true
}

# Private Subnet in Zone 2
resource "google_compute_subnetwork" "private_subnet_2" {
  name                     = "${var.project_prefix}-private-subnet-2-${var.environment}"
  ip_cidr_range            = var.private_subnet_cidr_2
  region                   = var.region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = true
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  name    = "${var.project_prefix}-router-${var.environment}"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}

# Cloud NAT for private subnets
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_prefix}-nat-${var.environment}"
  router                             = google_compute_router.router.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rule - Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_prefix}-allow-internal-${var.environment}"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.public_subnet_cidr_1,
    var.public_subnet_cidr_2,
    var.private_subnet_cidr_1,
    var.private_subnet_cidr_2
  ]
}

# Firewall rule - Allow SSH from IAP
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.project_prefix}-allow-iap-ssh-${var.environment}"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}
