variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "public_subnet_cidr_1" {
  description = "CIDR block for public subnet in zone 1"
  type        = string
}

variable "public_subnet_cidr_2" {
  description = "CIDR block for public subnet in zone 2"
  type        = string
}

variable "private_subnet_cidr_1" {
  description = "CIDR block for private subnet in zone 1"
  type        = string
}

variable "private_subnet_cidr_2" {
  description = "CIDR block for private subnet in zone 2"
  type        = string
}

variable "pods_cidr_1" {
  description = "CIDR block for pods in zone 1"
  type        = string
}

variable "pods_cidr_2" {
  description = "CIDR block for pods in zone 2"
  type        = string
}

variable "services_cidr_1" {
  description = "CIDR block for services in zone 1"
  type        = string
}

variable "services_cidr_2" {
  description = "CIDR block for services in zone 2"
  type        = string
}
