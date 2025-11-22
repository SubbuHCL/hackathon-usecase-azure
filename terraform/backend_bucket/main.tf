resource "google_storage_bucket" "backend_bucket" {
  name          = "${var.backend_bucket}"
  location      = "US-CENTRAL1"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
  lifecycle {
  prevent_destroy = true
  }
}