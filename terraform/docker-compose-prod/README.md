# RepoSwarm — Docker Compose Production (VM/VPS)

Deploy RepoSwarm on a single EC2 instance with Docker Compose. Ideal for small teams, demos, and VPS deployments.

## Architecture

```
Internet → Nginx (port 80/443)
              ├── /          → UI (Next.js :3000)
              ├── /v1/*      → API (Node.js :3001)
              └── /temporal  → Temporal UI (:8080)

Internal:
  Temporal Server (:7233) → Postgres (local container)
  Worker → Temporal + DynamoDB (AWS) + LLM
```

> **Note:** This template uses a local Postgres container for Temporal (simpler VM setup). For production-critical deployments, use the [ECS](../aws-ecs/) or [EKS](../aws-eks/) templates with RDS.

## Prerequisites

- AWS CLI configured
- Terraform >= 1.5
- SSH key pair
- GitHub or GitLab token
- Anthropic API key or Bedrock access

## Quick Start

```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
# Edit with your values

# 2. Deploy
terraform init
terraform plan
terraform apply

# 3. Access
# The output shows the public IP and SSH command
ssh ubuntu@<IP>

# 4. Check services
ssh ubuntu@<IP> "cd /opt/reposwarm && docker compose ps"
```

## What Gets Created

- **VPC** with a single public subnet
- **EC2 Instance** (t4g.xlarge by default, Ubuntu 24.04)
- **Elastic IP** for stable public access
- **DynamoDB** table for RepoSwarm cache
- **IAM Instance Profile** with DynamoDB + Secrets Manager access
- **Secrets Manager** secrets for tokens and keys
- **Security Group** allowing SSH + HTTP + HTTPS

## Services on the VM

All services run via Docker Compose with:
- **Restart policies** (`unless-stopped`)
- **Resource limits** (memory + CPU caps)
- **Health checks** on critical services
- **Named volumes** for data persistence
- **Nginx reverse proxy** for routing

## TLS/HTTPS

The template includes an Nginx container. To enable HTTPS:

1. Install certbot on the instance:
   ```bash
   apt-get install certbot python3-certbot-nginx
   certbot --nginx -d your-domain.com
   ```

2. Or use Cloudflare/Caddy for automatic TLS.

## Monitoring

SSH into the instance and use:

```bash
# Service status
docker compose ps

# Logs
docker compose logs -f api
docker compose logs -f worker

# Resource usage
docker stats
```

## Backup

Postgres data is stored in a Docker volume. Back it up with:

```bash
docker compose exec postgres pg_dump -U temporal temporal > backup.sql
```

## Scaling

This is a single-instance deployment. For scaling:
- **Vertical:** Change `instance_type` to a larger instance
- **Horizontal:** Use the [ECS](../aws-ecs/) or [EKS](../aws-eks/) templates

## Teardown

```bash
terraform destroy
```

## Cost Estimate

| Resource | Estimate |
|----------|----------|
| EC2 (t4g.xlarge) | ~$95/month |
| Elastic IP | Free (when attached) |
| DynamoDB (PAY_PER_REQUEST) | Usage-based |
| Secrets Manager | ~$2 |
| **Total** | **~$100/month** |
