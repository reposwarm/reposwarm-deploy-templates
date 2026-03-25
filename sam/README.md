# RepoSwarm — SAM Templates

> ⚠️ **Status: Placeholder** — Community contributions welcome!

This directory contains a minimal SAM template for potential serverless components of RepoSwarm.

## Why SAM?

The core RepoSwarm platform runs as long-lived containers. SAM could be useful for:
- **Webhook receivers** — GitHub/GitLab webhook handlers
- **Scheduled jobs** — Cleanup, maintenance tasks
- **Event processing** — SNS/SQS consumers for async workflows
- **API Gateway** — Fronting ECS services with caching and throttling

## Current State

The `template.yaml` creates a DynamoDB table and provides a skeleton for adding Lambda functions.

## For Production Use

Use the [Terraform templates](../terraform/) for deploying the core RepoSwarm platform.

## Contributing

1. Fork this repository
2. Add Lambda functions under `functions/`
3. Update `template.yaml`
4. Test with `sam build && sam local invoke`
5. Submit a pull request
