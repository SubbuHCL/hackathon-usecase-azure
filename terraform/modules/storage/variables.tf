variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}
