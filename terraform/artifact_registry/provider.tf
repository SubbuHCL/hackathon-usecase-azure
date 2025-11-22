terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.12.0"
    }
  }
}

provider "google" {
  # Configuration options
  project = "hcl-hackathon-479010"
  region = "us-central1"
}