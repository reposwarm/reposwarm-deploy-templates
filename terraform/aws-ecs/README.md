# RepoSwarm — AWS ECS Fargate Deployment

Deploy RepoSwarm on AWS ECS Fargate with Application Load Balancer, RDS Postgres, and DynamoDB.

## Architecture

```
Internet → ALB (HTTPS) → ECS Fargate
                            ├── UI (Next.js)          → DynamoDB
                            ├── API (Node.js)         → DynamoDB + Temporal
                            ├── Worker (Python)       → DynamoDB + Temporal + LLM
                            ├── Temporal Server       → RDS Postgres
                            └── Temporal UI
```

All services run in private subnets with NAT Gateway for outbound internet access. The ALB is the only public-facing resource.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5
- An AWS account with permissions to create VPC, ECS, RDS, DynamoDB, ALB, Secrets Manager, IAM resources
- (Optional) ACM certificate for HTTPS
- GitHub or GitLab personal access token
- Anthropic API key or AWS Bedrock access

## Quick Start

```bash
# 1. Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Initialize Terraform
terraform init

# 3. Review the plan
terraform plan

# 4. Deploy
terraform apply
```

## What Gets Created

| Resource | Description |
|----------|-------------|
| VPC | 3 public + 3 private subnets across 3 AZs |
| NAT Gateway | Single NAT (upgrade to per-AZ for HA) |
| ALB | Public-facing with HTTP/HTTPS listeners |
| ECS Cluster | Fargate with Container Insights enabled |
| RDS Postgres | Temporal's database (encrypted, backed up) |
| DynamoDB | RepoSwarm cache table (PAY_PER_REQUEST) |
| Secrets Manager | API token, git tokens, LLM keys, RDS password |
| CloudWatch | Log groups for all services |
| Service Discovery | Private DNS namespace for inter-service communication |

## Configuration

### Required Variables

| Variable | Description |
|----------|-------------|
| `api_bearer_token` | Shared secret for API authentication |
| `github_token` or `gitlab_token` | At least one git provider token |
| `anthropic_api_key` or `use_bedrock = true` | LLM access for the worker |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region |
| `environment` | `prod` | Environment name (used in resource naming) |
| `acm_certificate_arn` | `""` | ACM cert ARN for HTTPS |
| `rds_instance_class` | `db.t4g.medium` | RDS instance size |
| `rds_multi_az` | `false` | Enable Multi-AZ for RDS |
| `api_desired_count` | `2` | Number of API tasks |
| `worker_desired_count` | `2` | Number of worker tasks |
| `ui_desired_count` | `2` | Number of UI tasks |

## LLM Access

The worker needs access to an LLM. You have two options:

### Option 1: Anthropic API Key
Set `anthropic_api_key` in your tfvars. The key is stored in Secrets Manager and injected as an environment variable.

### Option 2: AWS Bedrock
Set `use_bedrock = true`. The worker's task role will be granted Bedrock InvokeModel permissions. Make sure the Anthropic Claude models are enabled in your region.

## Scaling

Adjust `*_desired_count` variables to scale services. For auto-scaling, add:

```hcl
resource "aws_appautoscaling_target" "api" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = "api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }
}
```

## Customization

### High Availability
- Set `rds_multi_az = true` for RDS
- Add NAT Gateways per AZ (modify `vpc.tf`)
- Increase `*_desired_count` for services

### Custom Domain
1. Create an ACM certificate for your domain
2. Set `acm_certificate_arn` to the cert ARN
3. Create a Route 53 alias record pointing to the ALB

### ARM64
The API, Worker, and UI tasks use ARM64 (Graviton) by default for better price/performance. Temporal and Temporal UI use the default (x86_64) since they're upstream images.

## Teardown

```bash
terraform destroy
```

> **Note:** RDS has deletion protection and a final snapshot. You may need to disable deletion protection first.

## Cost Estimate

Approximate monthly costs (us-east-1, minimal configuration):

| Resource | Estimate |
|----------|----------|
| NAT Gateway | ~$32 + data transfer |
| ALB | ~$16 + LCU charges |
| ECS Fargate (all services) | ~$100-200 |
| RDS (db.t4g.medium) | ~$55 |
| DynamoDB (PAY_PER_REQUEST) | Usage-based |
| Secrets Manager | ~$3 |
| **Total** | **~$200-300/month** |
