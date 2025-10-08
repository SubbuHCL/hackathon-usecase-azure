# Objective
Deploy the containerized microservices to GCP Kubernetes Service (GKE), demonstrating your skills in Kubernetes, containerization, and GCP services.

# Technical Requirements
Infrastructure as Code (Terraform)

Provision a VPC with public and private subnets
Set up an GKE cluster
Configure necessary IAM roles and security groups
Set up an GCR repository for your container images
## Containerization

Create a Dockerfile for the microservices
Build and push the Docker image to GCR
Kubernetes

Create Kubernetes deployment manifests
Set up a service and ingress for your applications
## CI/CD (GitHub Actions / Azure DevOps)

Implement a workflow for Terraform (lint, plan, apply)
Create a workflow for building and pushing Docker images
Implement a workflow for deploying to GKE
Monitoring and Logging

Set up GCloud Monitoring for cluster and application logging
(Bonus) Implement Prometheus and Grafana for monitoring
Deliverables
## GitHub repository containing:

1. Terraform code
2. Dockerfiles
3. Kubernetes manifests
4. GitHub Actions / Azure DevOps workflows
5. Application code (provided microservices)
## Documentation:

1. Architecture diagram
2. Setup and deployment instructions
3. Monitoring and logging overview