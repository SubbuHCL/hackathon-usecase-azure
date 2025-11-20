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

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "node_count" {
  description = "Number of nodes per zone"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes in the NodePool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the NodePool"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Disk size in GB for GKE nodes"
  type        = number
  default     = 50
}

variable "preemptible" {
  description = "Use preemptible nodes"
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Service account email for GKE nodes"
  type        = string
}

variable "default_node_disk_size_gb" {
  description = "Disk size in GB for the transient default node pool (small to avoid SSD quota)"
  type        = number
  default     = 12
}

variable "default_node_disk_type" {
  description = "Disk type for the transient default node pool"
  type        = string
  default     = "pd-standard"
}
