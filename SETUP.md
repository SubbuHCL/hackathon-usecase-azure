# Healthcare Application - GCP Setup Guide

Complete guide for deploying the healthcare application to Google Cloud Platform with Terraform and GitHub Actions.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring and Logging](#monitoring-and-logging)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- **Google Cloud SDK**: `gcloud` CLI installed and configured
- **Terraform**: Version >= 1.0
- **kubectl**: Kubernetes command-line tool
- **Docker**: For local testing
- **Git**: Version control
- **Node.js**: v18+ (for Node.js services)
- **Java**: JDK 17+ (for Order service)
- **Maven**: For building Java services

### GCP Requirements
- Active GCP account with billing enabled
- Project with Owner or Editor role
- APIs enabled:
  - Compute Engine API
  - Kubernetes Engine API
  - Artifact Registry API
  - Cloud Resource Manager API
  - IAM API
  - Cloud Logging API
  - Cloud Monitoring API

## Architecture Overview

### Infrastructure Components
```
┌─────────────────────────────────────────────────────────┐
│                    Google Cloud Platform                 │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │              VPC Network                        │    │
│  │  ┌─────────────────┐  ┌─────────────────┐     │    │
│  │  │  Public Subnet  │  │  Public Subnet  │     │    │
│  │  │   (Zone A)      │  │   (Zone B)      │     │    │
│  │  │                 │  │                 │     │    │
│  │  │   GKE Cluster   │  │   GKE Nodes     │     │    │
│  │  └─────────────────┘  └─────────────────┘     │    │
│  │                                                 │    │
│  │  ┌─────────────────┐  ┌─────────────────┐     │    │
│  │  │ Private Subnet  │  │ Private Subnet  │     │    │
│  │  │   (Zone A)      │  │   (Zone B)      │     │    │
│  │  └─────────────────┘  └─────────────────┘     │    │
│  │                                                 │    │
│  │           Cloud Router + NAT                   │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         Artifact Registry (Docker Images)       │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │    Cloud Storage (Terraform State)             │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │    Cloud Monitoring + Cloud Logging            │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### Application Services
- **Patient Service**: Node.js microservice (Port 3000)
- **Application Service**: Node.js microservice (Port 3001)
- **Order Service**: Java Spring Boot microservice (Port 8080)

## Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd hackathon-usecase
```

### 2. Configure GCP
```bash
# Set your project ID
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"

# Authenticate
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project $GCP_PROJECT_ID
```

### 3. Enable Required APIs
```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com
```

### 4. Create Terraform State Bucket
```bash
# Create GCS bucket for dev environment
gsutil mb -p $GCP_PROJECT_ID -l $GCP_REGION gs://healthcare-tfstate-dev-$GCP_PROJECT_ID

# Enable versioning
gsutil versioning set on gs://healthcare-tfstate-dev-$GCP_PROJECT_ID
```

### 5. Deploy Infrastructure
```bash
cd terraform/environments/dev

# Update terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars  # Add your project_id

# Update backend configuration in main.tf
sed -i "s/YOUR_PROJECT_ID/$GCP_PROJECT_ID/g" main.tf

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### 6. Configure kubectl
```bash
# Get cluster credentials
gcloud container clusters get-credentials healthcare-gke-dev \
  --region=$GCP_REGION \
  --project=$GCP_PROJECT_ID

# Verify connection
kubectl get nodes
```

### 7. Deploy Applications
```bash
# Create namespace
kubectl apply -f k8s/base/namespace.yaml

# Update service account with your project ID
sed -i "s/YOUR_PROJECT_ID/$GCP_PROJECT_ID/g" k8s/base/service-account.yaml

# Apply Kubernetes manifests
kubectl apply -f k8s/base/service-account.yaml
kubectl apply -f k8s/base/monitoring-config.yaml
kubectl apply -f k8s/base/
```

## Detailed Setup

### Step 1: Local Development Setup

#### Build Services Locally

**Patient Service (Node.js)**
```bash
cd patient-service
npm install
npm test
npm start  # Runs on port 3000
```

**Application Service (Node.js)**
```bash
cd application-service
npm install
npm test
npm start  # Runs on port 3001
```

**Order Service (Java)**
```bash
cd order-service
mvn clean install
mvn test
mvn spring-boot:run  # Runs on port 8080
```

#### Build Docker Images Locally
```bash
# Patient Service
docker build -t patient-service:local ./patient-service
docker run -p 3000:3000 patient-service:local

# Application Service
docker build -t application-service:local ./application-service
docker run -p 3001:3001 application-service:local

# Order Service
docker build -t order-service:local ./order-service
docker run -p 8080:8080 order-service:local
```

### Step 2: GCP Infrastructure Setup

#### Create Service Account for CI/CD
```bash
# Create service account
gcloud iam service-accounts create healthcare-cicd \
  --display-name="Healthcare CI/CD Service Account" \
  --project=$GCP_PROJECT_ID

# Grant necessary roles
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:healthcare-cicd@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:healthcare-cicd@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:healthcare-cicd@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create ~/healthcare-cicd-key.json \
  --iam-account=healthcare-cicd@$GCP_PROJECT_ID.iam.gserviceaccount.com
```

#### Configure Terraform Backend
```bash
cd terraform/environments/dev

# Update main.tf with your project ID
sed -i "s/YOUR_PROJECT_ID/$GCP_PROJECT_ID/g" main.tf

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
project_id     = "$GCP_PROJECT_ID"
project_prefix = "healthcare"
environment    = "dev"
region         = "us-central1"
EOF
```

#### Deploy Infrastructure with Terraform
```bash
# Initialize Terraform
terraform init

# Format and validate
terraform fmt
terraform validate

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Save outputs
terraform output -json > outputs.json
```

### Step 3: Kubernetes Setup

#### Update Kubernetes Manifests
```bash
# Update service account
sed -i "s/YOUR_PROJECT_ID/$GCP_PROJECT_ID/g" k8s/base/service-account.yaml

# Get Docker repository from Terraform output
DOCKER_REPO=$(terraform output -raw docker_repository)

# Update deployment images (you'll do this via CI/CD or manually)
# Example for manual update:
# kubectl set image deployment/patient-service patient-service=$DOCKER_REPO/patient-service:latest -n healthcare
```

#### Deploy to GKE
```bash
# Apply all base manifests
kubectl apply -f k8s/base/

# Check deployment status
kubectl get all -n healthcare

# Watch pods
kubectl get pods -n healthcare -w
```

## CI/CD Pipeline

### GitHub Actions Setup

#### 1. Configure GitHub Secrets
In your GitHub repository, add these secrets:

- `GCP_SA_KEY`: Contents of the service account JSON key file
- `GCP_PROJECT_ID`: Your GCP project ID

```bash
# Get the base64 encoded key for GitHub secret
cat ~/healthcare-cicd-key.json | base64
```

#### 2. Workflow Triggers

**Terraform Workflows**
- `terraform-pr.yml`: Runs on PR (fmt, validate, plan)
- `terraform-apply.yml`: Runs on merge to main (applies changes)

**Service Workflows**
- `ci-cd-patient-service.yml`: Build, test, push, deploy patient service
- `ci-cd-application-service.yml`: Build, test, push, deploy application service
- `ci-cd-order-service.yml`: Build, test, push, deploy order service

#### 3. Pipeline Flow

```
┌─────────────┐
│  Code Push  │
└──────┬──────┘
       │
       ├─────────────────┐
       │                 │
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│   Build &   │   │  Terraform  │
│    Test     │   │   Validate  │
└──────┬──────┘   └─────────────┘
       │
       ▼
┌─────────────┐
│   Docker    │
│   Build     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Push to    │
│  Artifact   │
│  Registry   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Deploy to  │
│     GKE     │
└─────────────┘
```

### Manual Deployment

If you want to deploy manually without CI/CD:

```bash
# Authenticate Docker with Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build and push patient service
docker build -t us-central1-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/patient-service:v1 ./patient-service
docker push us-central1-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/patient-service:v1

# Build and push application service
docker build -t us-central1-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/application-service:v1 ./application-service
docker push us-central1-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/application-service:v1

# Build and push order service
docker build -t us-central1-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/order-service:v1 ./order-service
docker push us-central1-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/order-service:v1

# Deploy to Kubernetes
kubectl set image deployment/patient-service patient-service=us-central1-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/patient-service:v1 -n healthcare
kubectl set image deployment/application-service application-service=us-central1-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/application-service:v1 -n healthcare
kubectl set image deployment/order-service order-service=us-central1-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/order-service:v1 -n healthcare
```

## Monitoring and Logging

### Cloud Logging

#### View Application Logs
```bash
# All healthcare namespace logs
gcloud logging read "resource.type=k8s_container AND resource.labels.namespace_name=healthcare" --limit 50

# Patient service logs
gcloud logging read "resource.type=k8s_container AND resource.labels.namespace_name=healthcare AND resource.labels.container_name=patient-service" --limit 50

# Error logs only
gcloud logging read "resource.type=k8s_container AND resource.labels.namespace_name=healthcare AND severity>=ERROR" --limit 50
```

### Cloud Monitoring

#### Access Dashboards
```bash
# List dashboards
gcloud monitoring dashboards list

# Open in browser
echo "https://console.cloud.google.com/monitoring/dashboards?project=$GCP_PROJECT_ID"
```

#### View Metrics
- Pod CPU and Memory usage
- HTTP request rates
- Error rates
- Latency percentiles

#### Alert Policies
- High error rate (>5% 5xx responses)
- Frequent pod restarts (>3 in 5 minutes)
- High CPU usage
- High memory usage

### Kubectl Monitoring Commands
```bash
# View pod status
kubectl get pods -n healthcare

# View pod logs
kubectl logs -f <pod-name> -n healthcare

# View pod events
kubectl describe pod <pod-name> -n healthcare

# View resource usage
kubectl top pods -n healthcare
kubectl top nodes

# Port forward for local access
kubectl port-forward svc/patient-service 3000:3000 -n healthcare
kubectl port-forward svc/application-service 3001:3001 -n healthcare
kubectl port-forward svc/order-service 8080:8080 -n healthcare
```

## Troubleshooting

### Common Issues

#### 1. Terraform State Lock
```bash
# If state is locked
terraform force-unlock <LOCK_ID>
```

#### 2. GKE Cluster Not Accessible
```bash
# Re-authenticate
gcloud container clusters get-credentials healthcare-gke-dev --region=us-central1

# Verify credentials
kubectl config current-context
```

#### 3. Pods Not Starting
```bash
# Check pod status
kubectl get pods -n healthcare

# Check pod logs
kubectl logs <pod-name> -n healthcare

# Check events
kubectl get events -n healthcare --sort-by='.lastTimestamp'

# Describe pod
kubectl describe pod <pod-name> -n healthcare
```

#### 4. Image Pull Errors
```bash
# Verify Artifact Registry permissions
gcloud artifacts repositories get-iam-policy healthcare-docker-dev --location=us-central1

# Check if image exists
gcloud artifacts docker images list us-central1-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev
```

#### 5. Service Not Accessible
```bash
# Check service
kubectl get svc -n healthcare

# Check endpoints
kubectl get endpoints -n healthcare

# Check ingress
kubectl get ingress -n healthcare
kubectl describe ingress -n healthcare
```

### Debugging Commands
```bash
# Execute command in pod
kubectl exec -it <pod-name> -n healthcare -- /bin/sh

# View all resources
kubectl get all -n healthcare

# Check resource quotas
kubectl describe resourcequota -n healthcare

# Check network policies
kubectl get networkpolicies -n healthcare
```

## Cleanup

### Delete Kubernetes Resources
```bash
kubectl delete namespace healthcare
```

### Destroy Terraform Infrastructure
```bash
cd terraform/environments/dev
terraform destroy
```

### Delete GCS State Bucket (Optional)
```bash
gsutil rm -r gs://healthcare-tfstate-dev-$GCP_PROJECT_ID
```

## Next Steps

1. **Configure custom domain**: Set up Cloud DNS and update ingress
2. **Add HTTPS**: Configure SSL certificates with cert-manager
3. **Set up staging/prod**: Replicate setup for other environments
4. **Configure monitoring alerts**: Add email/Slack notifications
5. **Implement autoscaling**: Configure HPA for services
6. **Add database**: Deploy Cloud SQL or Cloud Spanner
7. **Implement backup**: Set up automated backups
8. **Security hardening**: Add network policies, RBAC

## Support

For issues or questions, refer to:
- [Terraform Documentation](https://www.terraform.io/docs)
- [GCP Documentation](https://cloud.google.com/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- Project issues on GitHub
