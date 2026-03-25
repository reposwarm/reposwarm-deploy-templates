# RepoSwarm — AWS EKS Deployment

Deploy RepoSwarm on Amazon EKS with managed node groups, IRSA for IAM, and the RepoSwarm Helm chart.

## Architecture

```
Internet → Ingress Controller → K8s Services
                                   ├── UI (Next.js)
                                   ├── API (Node.js)       → DynamoDB (IRSA)
                                   ├── Worker (Python)     → DynamoDB + Bedrock (IRSA)
                                   ├── Temporal Server     → RDS Postgres
                                   └── Temporal UI
```

## Prerequisites

- AWS CLI configured
- Terraform >= 1.5
- kubectl
- Helm >= 3.x
- GitHub or GitLab token
- Anthropic API key or Bedrock access

## Quick Start

```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
# Edit with your values

# 2. Deploy infrastructure + Helm chart
terraform init
terraform plan
terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --name reposwarm-prod-eks --region us-east-1

# 4. Verify
kubectl get pods -n reposwarm
```

## What Gets Created

- **VPC** with public/private subnets (EKS-tagged)
- **EKS Cluster** with managed ARM64 node group (t4g.large)
- **RDS Postgres** for Temporal (encrypted, backed up)
- **DynamoDB** table for RepoSwarm cache
- **IRSA Roles** for API, Worker, and UI pods
- **Helm Release** deploying all RepoSwarm services

## IRSA (IAM Roles for Service Accounts)

Each service gets its own IAM role via IRSA:

| Service | Role | Permissions |
|---------|------|-------------|
| API | `reposwarm-prod-api-irsa` | DynamoDB read/write |
| Worker | `reposwarm-prod-worker-irsa` | DynamoDB read/write + Bedrock (optional) |
| UI | `reposwarm-prod-ui-irsa` | DynamoDB read-only |

## Using an Existing Cluster

If you already have an EKS cluster, you can deploy just the Helm chart:

```bash
helm install reposwarm ../../helm/reposwarm \
  --namespace reposwarm \
  --create-namespace \
  -f my-values.yaml
```

See the [Helm chart README](../../helm/reposwarm/README.md) for standalone usage.

## Ingress

The Helm chart includes an Ingress resource. You'll need an ingress controller installed (e.g., AWS Load Balancer Controller):

```bash
# Install AWS LB Controller (via Helm)
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=reposwarm-prod-eks
```

## Teardown

```bash
terraform destroy
```
