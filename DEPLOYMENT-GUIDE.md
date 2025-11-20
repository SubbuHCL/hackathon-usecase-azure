# Healthcare Application - Deployment Guide

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] GCP account with billing enabled
- [ ] gcloud CLI installed and authenticated
- [ ] Terraform >= 1.0 installed
- [ ] kubectl installed
- [ ] Git configured
- [ ] GitHub repository access
- [ ] Docker installed (for local testing)

## Step-by-Step Deployment

### Phase 1: Initial GCP Setup (15 minutes)

#### 1.1 Set Environment Variables
```bash
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
export ENVIRONMENT="dev"
```

#### 1.2 Authenticate with GCP
```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project $GCP_PROJECT_ID
```

#### 1.3 Enable Required APIs
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

**Checkpoint**: Run `gcloud services list --enabled` to verify all APIs are enabled.

### Phase 2: Terraform State Setup (5 minutes)

#### 2.1 Create GCS Bucket for State
```bash
# Create bucket
gsutil mb -p $GCP_PROJECT_ID -l $GCP_REGION gs://healthcare-tfstate-dev-$GCP_PROJECT_ID

# Enable versioning
gsutil versioning set on gs://healthcare-tfstate-dev-$GCP_PROJECT_ID

# Verify
gsutil ls gs://healthcare-tfstate-dev-$GCP_PROJECT_ID
```

#### 2.2 Create Service Account for CI/CD
```bash
# Create service account
gcloud iam service-accounts create healthcare-cicd-dev \
  --display-name="Healthcare CI/CD - Dev"

# Grant required roles
for role in roles/container.developer roles/artifactregistry.writer roles/storage.admin; do
  gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member="serviceAccount:healthcare-cicd-dev@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="$role"
done

# Create and download key
gcloud iam service-accounts keys create ~/healthcare-cicd-key.json \
  --iam-account=healthcare-cicd-dev@$GCP_PROJECT_ID.iam.gserviceaccount.com
```

**Checkpoint**: Verify key file exists: `ls -lh ~/healthcare-cicd-key.json`

### Phase 3: Infrastructure Deployment (20-30 minutes)

#### 3.1 Configure Terraform
```bash
cd terraform/environments/dev

# Update backend configuration
sed -i '' "s|YOUR_PROJECT_ID|${GCP_PROJECT_ID}|g" main.tf

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
project_id     = "$GCP_PROJECT_ID"
project_prefix = "healthcare"
environment    = "dev"
region         = "$GCP_REGION"
EOF
```

#### 3.2 Initialize Terraform
```bash
terraform init
terraform fmt
terraform validate
```

**Checkpoint**: Ensure no errors in validation output.

#### 3.3 Plan Infrastructure
```bash
terraform plan -out=tfplan
```

Review the plan carefully. You should see approximately:
- 1 VPC network
- 4 subnets (2 public, 2 private)
- 1 GKE cluster
- 1 node pool
- 3 service accounts
- 1 GCS bucket
- 1 Artifact Registry repository
- Various IAM bindings
- Firewall rules
- Cloud Router and NAT

#### 3.4 Apply Infrastructure
```bash
terraform apply tfplan
```

This will take 15-20 minutes. Monitor for any errors.

#### 3.5 Save Outputs
```bash
terraform output -json > outputs.json
cat outputs.json
```

**Checkpoint**: Verify all expected outputs are present.

### Phase 4: Kubernetes Configuration (10 minutes)

#### 4.1 Configure kubectl
```bash
cd ../../..  # Return to root directory

gcloud container clusters get-credentials healthcare-gke-dev \
  --region=$GCP_REGION \
  --project=$GCP_PROJECT_ID
```

#### 4.2 Verify Cluster Access
```bash
cd /Users/sandipreddynukalapati/Desktop/hackathon-usecase/terraform/environments/dev
terraform apply tfplan
```

You should see nodes in "Ready" state.

#### 4.3 Update Kubernetes Manifests
```bash
# Update service account with project ID
sed -i '' "s|YOUR_PROJECT_ID|${GCP_PROJECT_ID}|g" k8s/base/service-account.yaml


# Verify the change
grep "iam.gke.io" k8s/base/service-account.yaml
```

#### 4.4 Deploy Kubernetes Resources
```bash
# Create namespace
kubectl apply -f k8s/base/namespace.yaml

# Deploy service account and configs
kubectl config current-context
kubectl config view --minify -o yaml

# Verify
kubectl get namespace healthcare
kubectl get serviceaccount -n healthcare
```

**Checkpoint**: Run `kubectl get all -n healthcare` (should show namespace is ready).

### Phase 5: GitHub Actions Setup (10 minutes)

#### 5.1 Prepare Service Account Key
```bash
# Get base64 encoded key for GitHub
cat ~/healthcare-cicd-key.json | base64 > ~/gcp-sa-key-base64.txt

# Display for copying
cat ~/gcp-sa-key-base64.txt
```

#### 5.2 Add GitHub Secrets
Go to your GitHub repository:
1. Navigate to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add the following secrets:

| Secret Name | Value |
|-------------|-------|
| `GCP_SA_KEY` | Content from `~/gcp-sa-key-base64.txt` |
| `GCP_PROJECT_ID` | Your GCP project ID |

#### 5.3 Verify Workflows
```bash
# Check workflow files exist
ls -la .github/workflows/
```

You should see:
- `terraform-pr.yml`
- `terraform-apply.yml`
- `ci-cd-patient-service.yml`
- `ci-cd-application-service.yml`
- `ci-cd-order-service.yml`

**Checkpoint**: Create a test PR to verify Terraform validation workflow runs.

### Phase 6: Application Deployment (15 minutes)

#### 6.1 Build and Push Docker Images Manually (First Time)

**Option A: Using gcloud**
```bash
# Configure Docker
gcloud auth configure-docker $GCP_REGION-docker.pkg.dev

# Build and push patient service
cd patient-service
docker build -t $GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/patient-service:v1.0.0 .
docker push $GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/patient-service:v1.0.0
cd ..

# Build and push application service
cd application-service
docker build -t $GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/application-service:v1.0.0 .
docker push $GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/application-service:v1.0.0
cd ..

# Build and push order service
cd order-service
docker build -t $GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/order-service:v1.0.0 .
docker push $GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev/order-service:v1.0.0
cd ..
```

**Option B: Trigger GitHub Actions (Recommended)**
```bash
# Commit and push to trigger CI/CD
git add .
git commit -m "Deploy healthcare services"
git push origin main
```

#### 6.2 Deploy to Kubernetes
```bash
# Apply deployment manifests
kubectl apply -f k8s/base/

# Watch deployment progress
kubectl get pods -n healthcare -w
```

Wait for all pods to be in "Running" state (Ctrl+C to exit watch).

#### 6.3 Verify Deployments
```bash
# Check pods
kubectl get pods -n healthcare

# Check services
kubectl get svc -n healthcare

# Check deployments
kubectl get deployments -n healthcare

# View logs
kubectl logs -l app=patient-service -n healthcare --tail=50
kubectl logs -l app=application-service -n healthcare --tail=50
kubectl logs -l app=order-service -n healthcare --tail=50
```

**Checkpoint**: All pods should be in "Running" state with 1/1 or 2/2 ready.

### Phase 7: Verification and Testing (10 minutes)

#### 7.1 Port Forward Services for Testing
```bash
# Patient service
kubectl port-forward svc/patient-service 3000:3000 -n healthcare &

# Application service
kubectl port-forward svc/application-service 3001:3001 -n healthcare &

# Order service
kubectl port-forward svc/order-service 8080:8080 -n healthcare &
```

#### 7.2 Test Endpoints
```bash
# Test patient service
curl http://localhost:3000/health
curl http://localhost:3000/patients

# Test application service
curl http://localhost:3001/health
curl http://localhost:3001/appointments

# Test order service
curl http://localhost:8080/actuator/health
curl http://localhost:8080/orders
```

Expected responses: HTTP 200 OK with appropriate JSON responses.

#### 7.3 Check Monitoring
```bash
# View logs in Cloud Logging
gcloud logging read "resource.type=k8s_container AND resource.labels.namespace_name=healthcare" --limit=50 --format=json

# Access monitoring dashboard
echo "https://console.cloud.google.com/monitoring/dashboards?project=$GCP_PROJECT_ID"
```

**Checkpoint**: All health endpoints should return successful responses.

### Phase 8: Post-Deployment Validation (5 minutes)

#### 8.1 Resource Utilization
```bash
# Check node utilization
kubectl top nodes

# Check pod utilization
kubectl top pods -n healthcare
```

#### 8.2 Event Logs
```bash
# Check for any errors
kubectl get events -n healthcare --sort-by='.lastTimestamp' | tail -20
```

#### 8.3 Deployment Status
```bash
# Get overall status
kubectl get all -n healthcare

# Check rollout status
kubectl rollout status deployment/patient-service -n healthcare
kubectl rollout status deployment/application-service -n healthcare
kubectl rollout status deployment/order-service -n healthcare
```

## Common Issues and Solutions

### Issue 1: Terraform State Lock
**Symptom**: "Error acquiring the state lock"
```bash
terraform force-unlock <LOCK_ID>
```

### Issue 2: API Not Enabled
**Symptom**: "API [service] not enabled"
```bash
gcloud services enable <service-name>
```

### Issue 3: Image Pull Error
**Symptom**: "ImagePullBackOff" in pod status
```bash
# Check image exists
gcloud artifacts docker images list $GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/healthcare-docker-dev

# Verify IAM permissions
gcloud artifacts repositories get-iam-policy healthcare-docker-dev --location=$GCP_REGION
```

### Issue 4: Pod CrashLoopBackOff
**Symptom**: Pod continuously restarting
```bash
# View logs
kubectl logs <pod-name> -n healthcare --previous

# Describe pod
kubectl describe pod <pod-name> -n healthcare
```

### Issue 5: GitHub Actions Failing
**Symptom**: Workflow fails with authentication error
- Verify `GCP_SA_KEY` secret is correctly set
- Check service account has required permissions
- Ensure project ID in secret matches actual project

## Rollback Procedures

### Rollback Terraform Changes
```bash
cd terraform/environments/dev
terraform plan -destroy
terraform destroy  # Use with caution
```

### Rollback Kubernetes Deployment
```bash
# Rollback to previous version
kubectl rollout undo deployment/patient-service -n healthcare
kubectl rollout undo deployment/application-service -n healthcare
kubectl rollout undo deployment/order-service -n healthcare

# Verify rollback
kubectl rollout history deployment/patient-service -n healthcare
```

## Monitoring Checklist

After deployment, monitor:
- [ ] All pods are running
- [ ] Services are accessible
- [ ] Health checks passing
- [ ] Logs show no errors
- [ ] Metrics are being collected
- [ ] Alerts are configured
- [ ] GitHub Actions pipelines successful

## Success Criteria

Your deployment is successful when:
1. ✅ Terraform applies without errors
2. ✅ GKE cluster is running
3. ✅ All 3 services deployed successfully
4. ✅ All pods in "Running" state
5. ✅ Health endpoints return 200 OK
6. ✅ Logs visible in Cloud Logging
7. ✅ Metrics visible in Cloud Monitoring
8. ✅ GitHub Actions pipelines passing

## Next Steps

After successful deployment:
1. Configure custom domain and SSL
2. Set up Cloud SQL database
3. Implement autoscaling policies
4. Configure backup and disaster recovery
5. Set up staging environment
6. Document API endpoints
7. Create runbooks for operations

## Cleanup (When Done)

To remove all resources:
```bash
# Delete Kubernetes resources
kubectl delete namespace healthcare

# Destroy Terraform infrastructure
cd terraform/environments/dev
terraform destroy

# Delete state bucket
gsutil rm -r gs://healthcare-tfstate-dev-$GCP_PROJECT_ID

# Delete service account
gcloud iam service-accounts delete healthcare-cicd-dev@$GCP_PROJECT_ID.iam.gserviceaccount.com
```

## Support and Documentation

- **Detailed Setup**: [SETUP.md](SETUP.md)
- **Terraform Docs**: [terraform/README.md](terraform/README.md)
- **Implementation Guide**: [README-IMPLEMENTATION.md](README-IMPLEMENTATION.md)
- **GCP Console**: https://console.cloud.google.com
- **GitHub Repository**: Your repository URL

## Time Estimates

- **Initial Setup**: 15 minutes
- **State Setup**: 5 minutes
- **Infrastructure Deployment**: 20-30 minutes
- **Kubernetes Config**: 10 minutes
- **GitHub Setup**: 10 minutes
- **Application Deployment**: 15 minutes
- **Testing**: 10 minutes
- **Total**: ~90 minutes (first time)

Subsequent deployments via CI/CD: 5-10 minutes
