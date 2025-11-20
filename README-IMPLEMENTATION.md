# Healthcare Application - DevOps Implementation

## Overview

This repository contains a complete DevOps implementation for a healthcare application with three microservices deployed on Google Cloud Platform (GCP) using Terraform for Infrastructure as Code and GitHub Actions for CI/CD automation.

## 🏗️ Architecture

### Infrastructure Components

- **Google Kubernetes Engine (GKE)**: Container orchestration
- **VPC with Multi-AZ**: High availability across 2 availability zones
- **Cloud NAT & Router**: Secure outbound connectivity
- **Artifact Registry**: Docker image storage
- **Cloud Storage**: Terraform state management with locking
- **IAM & Workload Identity**: Secure service authentication
- **Cloud Monitoring & Logging**: Observability and monitoring

### Microservices

1. **Patient Service** (Node.js) - Port 3000
2. **Application Service** (Node.js) - Port 3001  
3. **Order Service** (Java/Spring Boot) - Port 8080

## 📁 Project Structure

```
.
├── terraform/                      # Infrastructure as Code
│   ├── modules/                   # Reusable Terraform modules
│   │   ├── vpc/                   # VPC, subnets, NAT, firewall
│   │   ├── gke/                   # GKE cluster and node pools
│   │   ├── iam/                   # Service accounts and IAM roles
│   │   └── storage/               # GCS buckets and Artifact Registry
│   ├── environments/              # Environment-specific configs
│   │   ├── dev/                   # Development environment
│   │   ├── staging/               # Staging environment
│   │   └── prod/                  # Production environment
│   ├── monitoring.tf              # Monitoring and alerting
│   └── README.md                  # Terraform documentation
│
├── .github/workflows/             # CI/CD Pipelines
│   ├── terraform-pr.yml           # Terraform validation on PRs
│   ├── terraform-apply.yml        # Terraform apply on merge
│   ├── ci-cd-patient-service.yml  # Patient service pipeline
│   ├── ci-cd-application-service.yml  # Application service pipeline
│   └── ci-cd-order-service.yml    # Order service pipeline
│
├── k8s/                           # Kubernetes manifests
│   ├── base/                      # Base configurations
│   │   ├── namespace.yaml         # Healthcare namespace
│   │   ├── service-account.yaml   # Workload Identity SA
│   │   ├── monitoring-config.yaml # Monitoring configuration
│   │   ├── patient-service-deployment.yaml
│   │   ├── application-service-deployment.yaml
│   │   ├── order-service-deployment.yaml
│   │   └── ingress.yaml          # Ingress configuration
│   └── overlays/                  # Environment overlays (kustomize)
│
├── patient-service/               # Node.js microservice
│   ├── src/
│   ├── Dockerfile
│   └── package.json
│
├── application-service/           # Node.js microservice
│   ├── src/
│   ├── Dockerfile
│   └── package.json
│
├── order-service/                 # Java microservice
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
│
├── scripts/
│   └── setup-gcp.sh              # Automated setup script
│
├── SETUP.md                       # Detailed setup guide
├── README.md                      # Project overview
└── .gitignore                     # Git ignore rules
```

## ✅ Implementation Checklist

### Infrastructure as Code (Terraform)

- [x] Multi-environment support (dev, staging, prod)
- [x] VPC with public and private subnets across 2 AZs
- [x] GKE cluster with auto-scaling node pools
- [x] IAM roles and service accounts
- [x] Remote state storage in GCS with versioning
- [x] State locking mechanism
- [x] Artifact Registry for Docker images
- [x] Cloud NAT for private subnet egress
- [x] Network security (firewall rules)
- [x] Workload Identity for secure pod authentication

### Containerization (Docker)

- [x] Dockerfiles for all 3 services
- [x] Multi-stage builds for optimization
- [x] Health checks in containers
- [x] Non-root user for security

### Kubernetes

- [x] Deployment manifests for all services
- [x] Service definitions
- [x] Namespace isolation
- [x] Ingress configuration
- [x] Service account with Workload Identity
- [x] ConfigMaps for configuration
- [x] Resource limits and requests
- [x] Liveness and readiness probes

### CI/CD (GitHub Actions)

- [x] Terraform validation on PRs (fmt, validate)
- [x] Terraform plan on PRs with PR comments
- [x] Terraform apply on merge to main
- [x] Build and test for all services
- [x] Docker image build and push to Artifact Registry
- [x] Automatic deployment to GKE
- [x] Separate workflows per service
- [x] Rollout status verification

### Monitoring and Logging

- [x] Cloud Logging integration
- [x] Cloud Monitoring setup
- [x] Log-based metrics
- [x] Custom dashboards
- [x] Alert policies for errors and restarts
- [x] Uptime checks
- [x] Application performance monitoring

## 🚀 Quick Start

### Prerequisites

- GCP account with billing enabled
- `gcloud` CLI installed
- Terraform >= 1.0
- kubectl installed
- Docker installed (for local testing)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd hackathon-usecase
   ```

2. **Configure GCP**
   ```bash
   export GCP_PROJECT_ID="your-project-id"
   gcloud auth login
   gcloud config set project $GCP_PROJECT_ID
   ```

3. **Enable APIs**
   ```bash
   gcloud services enable compute.googleapis.com container.googleapis.com \
     artifactregistry.googleapis.com iam.googleapis.com \
     logging.googleapis.com monitoring.googleapis.com
   ```

4. **Create Terraform state bucket**
   ```bash
   gsutil mb gs://healthcare-tfstate-dev-$GCP_PROJECT_ID
   gsutil versioning set on gs://healthcare-tfstate-dev-$GCP_PROJECT_ID
   ```

5. **Deploy infrastructure**
   ```bash
   cd terraform/environments/dev
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your project ID
   terraform init
   terraform apply
   ```

6. **Configure kubectl**
   ```bash
   gcloud container clusters get-credentials healthcare-gke-dev \
     --region=us-central1 --project=$GCP_PROJECT_ID
   ```

7. **Deploy applications**
   ```bash
   kubectl apply -f k8s/base/
   ```

For detailed setup instructions, see [SETUP.md](SETUP.md).

## 🔄 CI/CD Pipeline Flow

### Pull Request Flow
```
PR Created → Terraform Fmt/Validate → Terraform Plan → Comment Results on PR
           → Build & Test Services → Report Status
```

### Merge to Main Flow
```
Merge → Terraform Apply → Build Docker Images → Push to Artifact Registry → Deploy to GKE → Verify Rollout
```

### Service-Specific Pipelines

Each service has its own pipeline that:
1. Runs on changes to service code or K8s manifests
2. Installs dependencies and runs tests
3. Builds Docker image with versioned tags
4. Pushes to Artifact Registry
5. Updates K8s deployment
6. Verifies rollout status

## 📊 Monitoring and Observability

### Cloud Logging

View logs:
```bash
# All healthcare services
gcloud logging read "resource.type=k8s_container AND resource.labels.namespace_name=healthcare" --limit 50

# Specific service
gcloud logging read "resource.type=k8s_container AND resource.labels.container_name=patient-service" --limit 50

# Error logs only
gcloud logging read "severity>=ERROR AND resource.labels.namespace_name=healthcare" --limit 50
```

### Cloud Monitoring

- **Dashboard**: Healthcare Services Dashboard
- **Metrics**:
  - HTTP request rate
  - Error rate (4xx, 5xx)
  - Pod CPU and memory usage
  - Latency percentiles
- **Alerts**:
  - High error rate (>5%)
  - Frequent pod restarts (>3 in 5 min)

Access: https://console.cloud.google.com/monitoring/dashboards?project=YOUR_PROJECT_ID

### kubectl Commands

```bash
# View pod status
kubectl get pods -n healthcare

# View logs
kubectl logs -f <pod-name> -n healthcare

# View resource usage
kubectl top pods -n healthcare

# Port forward for testing
kubectl port-forward svc/patient-service 3000:3000 -n healthcare
```

## 🔒 Security Features

- **Workload Identity**: Secure service-to-service authentication
- **Private GKE nodes**: No public IPs on worker nodes
- **Network policies**: Traffic isolation between services
- **IAM least privilege**: Minimal required permissions
- **Service accounts**: Separate accounts for different workloads
- **Secret management**: Kubernetes secrets for sensitive data
- **Container scanning**: Automatic vulnerability scanning in Artifact Registry

## 🌍 Multi-Environment Strategy

### Environment Separation

| Feature | Dev | Staging | Prod |
|---------|-----|---------|------|
| Node Count | 1 | 2 | 3 |
| Machine Type | e2-medium | e2-standard-2 | e2-standard-4 |
| Preemptible | Yes | No | No |
| Auto-scaling Max | 3 | 5 | 10 |
| State Bucket | Separate | Separate | Separate |
| CIDR Blocks | 10.0.x.x | 10.10.x.x | 10.20.x.x |

### Promoting Changes

1. Test in **dev** environment
2. Merge to `main` for automatic dev deployment
3. Manually promote to **staging** (update workflow)
4. After validation, promote to **prod**

## 🛠️ Terraform Modules

### VPC Module
- Creates VPC with custom subnets
- Configures Cloud Router and NAT
- Sets up firewall rules
- Defines secondary IP ranges for GKE

### GKE Module
- Provisions GKE cluster
- Configures node pools with auto-scaling
- Enables Workload Identity
- Sets up monitoring and logging

### IAM Module
- Creates service accounts
- Assigns IAM roles
- Configures Workload Identity bindings

### Storage Module
- Creates GCS buckets
- Sets up Artifact Registry
- Configures lifecycle policies

## 📦 GitHub Secrets Required

Add these secrets to your GitHub repository:

- `GCP_SA_KEY`: Service account JSON key (base64 encoded)
- `GCP_PROJECT_ID`: Your GCP project ID

## 🧪 Testing

### Local Testing

```bash
# Node.js services
cd patient-service
npm install
npm test
npm start

# Java service
cd order-service
mvn clean test
mvn spring-boot:run
```

### Docker Testing

```bash
# Build and run locally
docker build -t patient-service:test ./patient-service
docker run -p 3000:3000 patient-service:test
```

### Integration Testing

```bash
# Port forward services
kubectl port-forward svc/patient-service 3000:3000 -n healthcare &
kubectl port-forward svc/application-service 3001:3001 -n healthcare &
kubectl port-forward svc/order-service 8080:8080 -n healthcare &

# Test endpoints
curl http://localhost:3000/health
curl http://localhost:3001/health
curl http://localhost:8080/actuator/health
```

## 🐛 Troubleshooting

### Common Issues

1. **Terraform state locked**: `terraform force-unlock <LOCK_ID>`
2. **GKE auth issues**: Re-run `gcloud container clusters get-credentials`
3. **Image pull errors**: Check Artifact Registry permissions
4. **Pod crashes**: Check logs with `kubectl logs <pod-name> -n healthcare`
5. **Service unreachable**: Verify service and endpoints with `kubectl get svc,endpoints -n healthcare`

See [SETUP.md](SETUP.md) for detailed troubleshooting.

## 📚 Documentation

- [SETUP.md](SETUP.md) - Detailed setup and deployment guide
- [terraform/README.md](terraform/README.md) - Terraform-specific documentation
- [readme-gcp.md](readme-gcp.md) - GCP-specific information

## 🎯 DevOps Best Practices Implemented

- ✅ Infrastructure as Code (Terraform)
- ✅ Containerization (Docker)
- ✅ Orchestration (Kubernetes)
- ✅ CI/CD Automation (GitHub Actions)
- ✅ Multi-environment support
- ✅ State management and locking
- ✅ Secrets management
- ✅ Monitoring and logging
- ✅ Auto-scaling
- ✅ High availability (multi-AZ)
- ✅ Security best practices
- ✅ GitOps workflow
- ✅ Automated testing
- ✅ Zero-downtime deployments

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Test locally
4. Create PR
5. Wait for CI checks
6. Merge after approval

## 📝 License

MIT

## 👥 Authors

DevOps Team - Healthcare Application Project

## 🆘 Support

For questions or issues:
- Check documentation in `SETUP.md`
- Review Terraform module documentation
- Open GitHub issue
- Contact DevOps team
