# Terraform Infrastructure for Healthcare Application

This directory contains Terraform configurations for deploying the healthcare application infrastructure on Google Cloud Platform (GCP).

## Directory Structure

```
terraform/
├── modules/              # Reusable Terraform modules
│   ├── vpc/             # VPC and networking resources
│   ├── gke/             # Google Kubernetes Engine cluster
│   ├── iam/             # IAM roles and service accounts
│   └── storage/         # GCS buckets and Artifact Registry
├── environments/         # Environment-specific configurations
│   ├── dev/             # Development environment
│   ├── staging/         # Staging environment
│   └── prod/            # Production environment
├── monitoring.tf        # Monitoring and logging configuration
└── monitoring-variables.tf
```

## Prerequisites

1. **GCP Account**: Active GCP account with billing enabled
2. **Terraform**: Version >= 1.0
3. **gcloud CLI**: Installed and configured
4. **Permissions**: Required GCP roles:
   - `roles/owner` or custom role with necessary permissions
   - `roles/iam.serviceAccountAdmin`
   - `roles/storage.admin`
   - `roles/container.admin`

## Setup Instructions

### 1. Initial Setup (First Time Only)

Create a GCS bucket for Terraform state (do this manually before running Terraform):

```bash
# Set your GCP project ID
export GCP_PROJECT_ID="your-project-id"

# Create state buckets for each environment
gsutil mb -p $GCP_PROJECT_ID -l us-central1 gs://healthcare-tfstate-dev-$GCP_PROJECT_ID
gsutil mb -p $GCP_PROJECT_ID -l us-central1 gs://healthcare-tfstate-staging-$GCP_PROJECT_ID
gsutil mb -p $GCP_PROJECT_ID -l us-central1 gs://healthcare-tfstate-prod-$GCP_PROJECT_ID

# Enable versioning
gsutil versioning set on gs://healthcare-tfstate-dev-$GCP_PROJECT_ID
gsutil versioning set on gs://healthcare-tfstate-staging-$GCP_PROJECT_ID
gsutil versioning set on gs://healthcare-tfstate-prod-$GCP_PROJECT_ID
```

### 2. Configure Environment Variables

For each environment (dev/staging/prod):

```bash
cd terraform/environments/dev  # or staging/prod

# Copy example tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vi terraform.tfvars
```

Update the backend configuration in `main.tf`:
```hcl
backend "gcs" {
  bucket = "healthcare-tfstate-dev-YOUR_PROJECT_ID"  # Replace with your project ID
  prefix = "terraform/state"
}
```

### 3. Initialize Terraform

```bash
cd terraform/environments/dev

# Authenticate with GCP
gcloud auth application-default login

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
```

### 4. Plan and Apply

```bash
# Review the execution plan
terraform plan

# Apply the configuration
terraform apply

# Save outputs
terraform output > outputs.txt
```

## Environment-Specific Configurations

### Development Environment
- **Node Count**: 1 per zone
- **Machine Type**: e2-medium
- **Preemptible**: true (cost-saving)
- **Auto-scaling**: 1-3 nodes

### Staging Environment
- **Node Count**: 2 per zone
- **Machine Type**: e2-standard-2
- **Preemptible**: false
- **Auto-scaling**: 2-5 nodes

### Production Environment
- **Node Count**: 3 per zone
- **Machine Type**: e2-standard-4
- **Preemptible**: false
- **Auto-scaling**: 3-10 nodes

## State Management

### Remote State
Terraform state is stored in GCS buckets with:
- **Versioning**: Enabled (keeps history of state files)
- **Encryption**: Server-side encryption by default
- **Locking**: Automatic with GCS backend

### Workspace Separation
Each environment has its own:
- GCS bucket for state storage
- Configuration directory
- Network CIDR ranges
- Resource naming convention

## Module Documentation

### VPC Module
Creates:
- VPC network
- Public subnets (2 AZs)
- Private subnets (2 AZs)
- Cloud Router and NAT
- Firewall rules
- Secondary IP ranges for GKE pods and services

### GKE Module
Creates:
- GKE cluster with private nodes
- Node pools with auto-scaling
- Workload Identity enabled
- Monitoring and logging enabled
- Network policies

### IAM Module
Creates:
- Service account for GKE nodes
- Service account for CI/CD pipelines
- Service account for Workload Identity
- IAM role bindings

### Storage Module
Creates:
- GCS bucket for Terraform state
- Artifact Registry repository for Docker images
- Lifecycle policies

## Monitoring and Logging

The infrastructure includes:
- **Cloud Logging**: Centralized logging for all services
- **Cloud Monitoring**: Metrics and dashboards
- **Uptime Checks**: Health monitoring for services
- **Alert Policies**: Notifications for errors and incidents
- **Custom Dashboards**: Application-specific metrics

Access monitoring:
```bash
# View logs
gcloud logging read "resource.type=k8s_pod AND resource.labels.namespace_name=healthcare" --limit 50

# View metrics dashboard
gcloud monitoring dashboards list
```

## CI/CD Integration

GitHub Actions workflows automatically:
1. Run `terraform fmt -check` on PRs
2. Run `terraform validate` on PRs
3. Run `terraform plan` and comment on PRs
4. Run `terraform apply` on merge to main

Required GitHub Secrets:
- `GCP_SA_KEY`: Service account JSON key
- `GCP_PROJECT_ID`: GCP project ID

## Cleanup

To destroy resources:

```bash
cd terraform/environments/dev

# Review what will be destroyed
terraform plan -destroy

# Destroy resources
terraform destroy

# Confirm by typing 'yes'
```

⚠️ **Warning**: This will delete all resources in the environment, including data in databases and storage.

## Troubleshooting

### Common Issues

1. **Backend initialization fails**
   ```bash
   # Ensure bucket exists
   gsutil ls gs://healthcare-tfstate-dev-YOUR_PROJECT_ID
   ```

2. **API not enabled**
   ```bash
   # Enable required APIs
   gcloud services enable compute.googleapis.com container.googleapis.com
   ```

3. **Insufficient permissions**
   ```bash
   # Check your permissions
   gcloud projects get-iam-policy $GCP_PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:user:$(gcloud config get-value account)"
   ```

4. **State lock issues**
   ```bash
   # Force unlock (use with caution)
   terraform force-unlock LOCK_ID
   ```

## Best Practices

1. **Always run `terraform plan` before `apply`**
2. **Review changes in PRs before merging**
3. **Use separate service accounts for CI/CD**
4. **Keep state files secure and encrypted**
5. **Tag resources consistently**
6. **Document any manual changes**
7. **Regularly update Terraform and provider versions**
8. **Test changes in dev before promoting to prod**

## Support

For issues or questions:
1. Check the Terraform documentation
2. Review GCP provider documentation
3. Check GitHub Issues
4. Contact the DevOps team

## License

MIT
