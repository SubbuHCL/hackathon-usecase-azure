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

variable "k8s_namespace" {
  description = "Kubernetes namespace for workload identity"
  type        = string
  default     = "healthcare"
}

variable "k8s_service_account" {
  description = "Kubernetes service account for workload identity"
  type        = string
  default     = "healthcare-sa"
}
