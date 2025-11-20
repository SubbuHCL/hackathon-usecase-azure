# Quick Start Guide - Healthcare Application on GCP

Get up and running in 10 minutes (after GCP setup).

## Prerequisites

- GCP account with billing enabled
- `gcloud` CLI installed
- Terraform >= 1.0
- kubectl installed

## Quick Setup

### 1. Set Variables (1 min)
```bash
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
```

### 2. Authenticate (1 min)
```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project $GCP_PROJECT_ID
```

### 3. Enable APIs (2 min)
```bash
gcloud services enable compute.googleapis.com container.googleapis.com \
  artifactregistry.googleapis.com iam.googleapis.com \
  logging.googleapis.com monitoring.googleapis.com
```

### 4. Create State Bucket (1 min)
```bash
gsutil mb gs://healthcare-tfstate-dev-$GCP_PROJECT_ID
gsutil versioning set on gs://healthcare-tfstate-dev-$GCP_PROJECT_ID
```

### 5. Deploy Infrastructure (20 min)
```bash
cd terraform/environments/dev

# Configure
sed -i '' "s|YOUR_PROJECT_ID|${GCP_PROJECT_ID}|g" main.tf
cat > terraform.tfvars <<EOF
project_id = "$GCP_PROJECT_ID"
project_prefix = "healthcare"
environment = "dev"
region = "$GCP_REGION"
EOF

# Deploy
terraform init
terraform apply -auto-approve
```

### 6. Configure kubectl (1 min)
```bash
cd ../../..
gcloud container clusters get-credentials healthcare-gke-dev \
  --region=$GCP_REGION --project=$GCP_PROJECT_ID
```

### 7. Deploy Apps (5 min)
```bash
# Update manifests
sed -i "s/YOUR_PROJECT_ID/$GCP_PROJECT_ID/g" k8s/base/service-account.yaml

# Deploy
kubectl apply -f k8s/base/
kubectl get pods -n healthcare -w
```

### 8. Test (2 min)
```bash
# Port forward
kubectl port-forward svc/patient-service 3000:3000 -n healthcare &
kubectl port-forward svc/application-service 3001:3001 -n healthcare &
kubectl port-forward svc/order-service 8080:8080 -n healthcare &

# Test
curl http://localhost:3000/health
curl http://localhost:3001/health
curl http://localhost:8080/actuator/health
```

## GitHub Actions Setup

1. Create service account:
```bash
gcloud iam service-accounts create healthcare-cicd-dev \
  --display-name="Healthcare CI/CD"

for role in roles/container.developer roles/artifactregistry.writer roles/storage.admin; do
  gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member="serviceAccount:healthcare-cicd-dev@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="$role"
done

gcloud iam service-accounts keys create ~/healthcare-cicd-key.json \
  --iam-account=healthcare-cicd-dev@$GCP_PROJECT_ID.iam.gserviceaccount.com
```

2. Add GitHub secrets:
   - `GCP_SA_KEY`: `cat ~/healthcare-cicd-key.json | base64`
   - `GCP_PROJECT_ID`: Your project ID

3. Push code to trigger pipelines!

## What's Deployed?

- ✅ VPC with multi-AZ subnets
- ✅ GKE cluster with 1 node (auto-scales 1-3)
- ✅ 3 microservices (Patient, Application, Order)
- ✅ Artifact Registry for Docker images
- ✅ Cloud Monitoring and Logging
- ✅ IAM roles and service accounts
- ✅ CI/CD pipelines via GitHub Actions

## Common Commands

```bash
# View pods
kubectl get pods -n healthcare

# View logs
kubectl logs -f <pod-name> -n healthcare

# Scale deployment
kubectl scale deployment patient-service --replicas=3 -n healthcare

# View GCP logs
gcloud logging read "resource.type=k8s_container AND resource.labels.namespace_name=healthcare" --limit=20

# View monitoring
gcloud monitoring dashboards list
```

## Cleanup

```bash
cd terraform/environments/dev
terraform destroy -auto-approve
gsutil rm -r gs://healthcare-tfstate-dev-$GCP_PROJECT_ID
```

## Need Help?

- **Detailed Setup**: [SETUP.md](SETUP.md)
- **Step-by-Step**: [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)
- **Implementation**: [README-IMPLEMENTATION.md](README-IMPLEMENTATION.md)
- **Terraform Docs**: [terraform/README.md](terraform/README.md)

## Troubleshooting

**Pods not starting?**
```bash
kubectl describe pod <pod-name> -n healthcare
kubectl logs <pod-name> -n healthcare
```

**Terraform errors?**
```bash
terraform init -upgrade
terraform validate
```

**Can't connect to cluster?**
```bash
gcloud container clusters get-credentials healthcare-gke-dev \
  --region=$GCP_REGION --project=$GCP_PROJECT_ID
```

## Success! 🎉

Your healthcare application is now running on GKE with:
- Infrastructure as Code (Terraform)
- CI/CD pipelines (GitHub Actions)
- Monitoring and logging (Cloud Operations)
- Auto-scaling and high availability

Deploy changes by pushing to GitHub - CI/CD handles the rest!
