terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "gcs" {
    bucket = "healthcare-tfstate-prod-YOUR_PROJECT_ID"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  project_id     = var.project_id
  project_prefix = var.project_prefix
  environment    = var.environment
  k8s_namespace  = var.k8s_namespace
  k8s_service_account = var.k8s_service_account
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_id            = var.project_id
  project_prefix        = var.project_prefix
  environment           = var.environment
  region                = var.region
  public_subnet_cidr_1  = "10.20.1.0/24"
  public_subnet_cidr_2  = "10.20.2.0/24"
  private_subnet_cidr_1 = "10.20.10.0/24"
  private_subnet_cidr_2 = "10.20.11.0/24"
  pods_cidr_1           = "10.21.0.0/16"
  pods_cidr_2           = "10.22.0.0/16"
  services_cidr_1       = "10.23.0.0/16"
  services_cidr_2       = "10.24.0.0/16"
}

# GKE Module
module "gke" {
  source = "../../modules/gke"

  project_id            = var.project_id
  project_prefix        = var.project_prefix
  environment           = var.environment
  region                = var.region
  vpc_name              = module.vpc.vpc_name
  subnet_name           = module.vpc.public_subnet_1_name
  service_account_email = module.iam.gke_nodes_service_account_email
  node_count            = 3
  min_node_count        = 3
  max_node_count        = 10
  machine_type          = "e2-standard-4"
  preemptible           = false

  depends_on = [module.vpc, module.iam]
}

# Storage Module
module "storage" {
  source = "../../modules/storage"

  project_id     = var.project_id
  project_prefix = var.project_prefix
  environment    = var.environment
  region         = var.region
}

resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = module.iam.workload_identity_service_account_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account}]"

  depends_on = [module.gke]
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}
