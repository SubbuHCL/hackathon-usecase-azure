# Overview
Welcome to the DevOps Hackathon Challenge! In this hackathon, you will demonstrate your skills in containerization, Infrastructure as Code (IaC), CI/CD, and cloud deployment using Azure / GCP services. You will be working with a simple healthcare application consisting of two microservices.

# Common Requirements
Regardless of the track you choose, you will be working with the following common elements:

## Microservices: 
You will be provided with two Node.js microservices - a Patient Service and an Appointment Service. The code for these services can be found in the Sample Microservices Code file.

## Containerization: 
You need to containerize these microservices using Docker.

## Infrastructure as Code (Terraform):

Set up a Terraform project structure supporting multiple environments (dev, staging, prod).
Provision the following Azure / GCP resources:
VPC with public and private subnets across two availability zones
IAM roles and security groups
Storage for Terraform state storage
State locking
(Other resources specific to your chosen track)
Terraform State Management:

Implement remote state storage using Blob Storage / GCP Files
Set up state locking
Configure workspace separation for different environments
## GitHub Actions / Azure DevOps for IaC:
Create workflows for:
Terraform fmt and validate on all PRs
Terraform plan on pull requests
Terraform apply on merges to main branch
CI/CD: Implement a CI/CD pipeline using GitHub Actions for your application code.

## Monitoring and Logging: 
Set up basic monitoring and logging using Azure Monitor / GCP.
