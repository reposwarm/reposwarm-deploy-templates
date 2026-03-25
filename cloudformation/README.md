# RepoSwarm — CloudFormation Templates

> ⚠️ **Status: Placeholder** — Community contributions welcome!

This directory contains a basic CloudFormation template that creates foundational resources for RepoSwarm on AWS. It's intended as a starting point, not a complete deployment.

## Current Coverage

The `ecs-stack.yaml` template creates:
- VPC
- DynamoDB table for caching
- Secrets Manager secret for API token
- ECS cluster

## What's Needed

Community contributions are welcome for:
- [ ] VPC networking (subnets, NAT, route tables)
- [ ] ALB with HTTPS listener
- [ ] RDS Postgres for Temporal
- [ ] ECS task definitions for all services
- [ ] ECS Fargate services
- [ ] IAM roles with least-privilege policies
- [ ] CloudWatch log groups
- [ ] Service Discovery namespace

## For Production Use

We recommend the [Terraform ECS template](../terraform/aws-ecs/) which provides a complete, tested deployment with all resources.

## Contributing

1. Fork this repository
2. Expand the `ecs-stack.yaml` template
3. Test with `aws cloudformation validate-template`
4. Submit a pull request

Please follow AWS best practices:
- Use `Ref` and `Fn::Sub` for resource references
- Include `DeletionPolicy` on stateful resources
- Add meaningful outputs
- Tag all resources with `Project: reposwarm`
