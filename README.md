# RepoSwarm Deploy Templates

Production deployment templates for [RepoSwarm](https://github.com/reposwarm) — a repository analysis platform powered by AI.

## 🏗️ Deployment Options

| Template | Description | Best For |
|----------|-------------|----------|
| [Terraform — AWS ECS](./terraform/aws-ecs/) | ECS Fargate + ALB + RDS + DynamoDB | Production workloads, fully managed containers |
| [Terraform — AWS EKS](./terraform/aws-eks/) | EKS + Helm chart + IRSA | Teams already using Kubernetes |
| [Terraform — Docker Compose (VM)](./terraform/docker-compose-prod/) | EC2 + production-hardened Docker Compose | Small teams, VPS/VM deployments |
| [Helm Chart](./helm/reposwarm/) | Kubernetes Helm chart | Existing K8s clusters |
| [CloudFormation](./cloudformation/) | Basic ECS stack (placeholder) | AWS-native IaC preference |
| [SAM](./sam/) | Serverless template (placeholder) | Future serverless components |

> **Looking for local development?** Use `reposwarm new --local` from the [RepoSwarm CLI](https://github.com/reposwarm/cli).

## 📦 RepoSwarm Services

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| **API** | `ghcr.io/reposwarm/api:latest` | 3000 | Node.js API server |
| **Worker** | `ghcr.io/reposwarm/worker:latest` | — | Python investigation worker |
| **UI** | `ghcr.io/reposwarm/ui:latest` | 3000 | Next.js dashboard |
| **Temporal** | `temporalio/auto-setup:latest` | 7233 | Workflow engine |
| **Temporal UI** | `temporalio/ui:latest` | 8080 | Temporal dashboard |
| **Postgres** | `postgres:16-alpine` | 5432 | Temporal database (use RDS in cloud) |
| **Askbox** | `ghcr.io/reposwarm/askbox:latest` | — | Optional Q&A service |

## 🔑 Prerequisites

All deployment templates require:

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.5 (for Terraform templates)
3. **Helm** >= 3.x (for Helm chart)
4. **GitHub/GitLab Token** — for the worker to clone repositories
5. **LLM Access** — either:
   - `ANTHROPIC_API_KEY` for direct Anthropic API access, or
   - AWS Bedrock access (set `CLAUDE_CODE_USE_BEDROCK=1`)
6. **API Bearer Token** — shared secret for API authentication
7. **(Optional) ACM Certificate** — for HTTPS on ALB/Ingress

## 🚀 Quick Start

### ECS Fargate (Recommended)

```bash
cd terraform/aws-ecs
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

### EKS + Helm

```bash
cd terraform/aws-eks
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# Or deploy Helm chart to existing cluster
helm install reposwarm ./helm/reposwarm -f my-values.yaml
```

### Docker Compose on VM

```bash
cd terraform/docker-compose-prod
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
# SSH into the instance and check docker compose logs
```

## 🏛️ Architecture Overview

```
                    ┌─────────────┐
                    │   ALB/Ingress│
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         ┌────▼───┐  ┌────▼───┐  ┌────▼────┐
         │  UI    │  │  API   │  │Temporal │
         │ :3000  │  │ :3000  │  │  UI     │
         └────────┘  └───┬────┘  │ :8080   │
                         │       └────┬────┘
                    ┌────▼────┐  ┌────▼────┐
                    │Temporal │◄─┤ Worker  │
                    │ :7233   │  └────┬────┘
                    └────┬────┘       │
                    ┌────▼────┐  ┌────▼────┐
                    │  RDS    │  │DynamoDB │
                    │Postgres │  │  Cache  │
                    └─────────┘  └─────────┘
```

## 📖 Documentation

Each template directory contains its own `README.md` with:
- Detailed prerequisites
- Step-by-step deployment guide
- Architecture diagram
- Configuration reference
- Troubleshooting tips

## 🤝 Contributing

Contributions are welcome! The CloudFormation and SAM templates are especially looking for community input.

## 📄 License

MIT
