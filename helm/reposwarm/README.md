# RepoSwarm Helm Chart

Deploy RepoSwarm on any Kubernetes cluster.

## Prerequisites

- Kubernetes 1.25+
- Helm 3.x
- (Optional) AWS credentials for DynamoDB access
- (Optional) Ingress controller for external access

## Quick Start

```bash
# Install with default values (in-cluster Postgres)
helm install reposwarm . \
  --namespace reposwarm \
  --create-namespace \
  --set secrets.apiBearerToken=my-token \
  --set secrets.githubToken=ghp_xxx \
  --set secrets.anthropicApiKey=sk-ant-xxx

# Install with external RDS
helm install reposwarm . \
  --namespace reposwarm \
  --create-namespace \
  --set postgres.enabled=false \
  --set temporal.postgres.host=my-rds.xxx.us-east-1.rds.amazonaws.com \
  --set temporal.postgres.password=xxx \
  --set secrets.apiBearerToken=my-token \
  --set secrets.githubToken=ghp_xxx
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgres.enabled` | Deploy in-cluster Postgres | `true` |
| `temporal.postgres.host` | External Postgres host (when `postgres.enabled=false`) | `""` |
| `aws.region` | AWS region for DynamoDB | `us-east-1` |
| `aws.dynamodbTable` | DynamoDB table name | `reposwarm-cache` |
| `secrets.apiBearerToken` | API authentication token | `""` |
| `secrets.githubToken` | GitHub PAT for worker | `""` |
| `secrets.anthropicApiKey` | Anthropic API key | `""` |
| `worker.useBedrock` | Use Bedrock instead of Anthropic | `"false"` |
| `ingress.enabled` | Enable Ingress resource | `false` |

### IRSA (AWS EKS)

For EKS with IRSA, annotate service accounts:

```yaml
api:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/reposwarm-api-irsa

worker:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/reposwarm-worker-irsa
```

### Ingress

```yaml
ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
  hosts:
    - host: reposwarm.example.com
      paths:
        - path: /v1
          pathType: Prefix
          service: api
        - path: /
          pathType: Prefix
          service: ui
  tls:
    - secretName: reposwarm-tls
      hosts:
        - reposwarm.example.com
```

## Components

| Component | Default Replicas | Notes |
|-----------|-----------------|-------|
| Postgres | 1 (StatefulSet) | Disable for external RDS |
| Temporal | 1 | Workflow engine |
| Temporal UI | 1 | Dashboard |
| API | 2 | Node.js API server |
| Worker | 2 | Investigation worker |
| UI | 2 | Next.js dashboard |

## Uninstall

```bash
helm uninstall reposwarm -n reposwarm
kubectl delete namespace reposwarm
```
