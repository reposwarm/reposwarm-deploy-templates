# --------------------------------------------------
# Outputs
# --------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "ALB DNS name — point your domain here"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID for Route 53 alias records"
  value       = aws_lb.main.zone_id
}

output "api_url" {
  description = "RepoSwarm API URL"
  value       = var.acm_certificate_arn != "" ? "https://${aws_lb.main.dns_name}" : "http://${aws_lb.main.dns_name}"
}

output "ui_url" {
  description = "RepoSwarm UI URL"
  value       = var.acm_certificate_arn != "" ? "https://${aws_lb.main.dns_name}" : "http://${aws_lb.main.dns_name}"
}

output "temporal_ui_url" {
  description = "Temporal UI URL (internal — access via port-forward or VPN)"
  value       = "http://${aws_service_discovery_service.temporal_ui.name}.${aws_service_discovery_private_dns_namespace.main.name}:8080"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "rds_endpoint" {
  description = "RDS Postgres endpoint"
  value       = aws_db_instance.temporal.endpoint
}

output "dynamodb_table_name" {
  description = "DynamoDB cache table name"
  value       = aws_dynamodb_table.cache.name
}
