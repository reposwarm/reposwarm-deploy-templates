# --------------------------------------------------
# Outputs
# --------------------------------------------------

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_ca" {
  description = "EKS cluster CA certificate (base64)"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "dynamodb_table_name" {
  description = "DynamoDB cache table name"
  value       = aws_dynamodb_table.cache.name
}

output "rds_endpoint" {
  description = "RDS Postgres endpoint"
  value       = aws_db_instance.temporal.endpoint
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
}

output "worker_irsa_role_arn" {
  description = "IAM role ARN for worker pods (IRSA)"
  value       = aws_iam_role.worker_irsa.arn
}

output "api_irsa_role_arn" {
  description = "IAM role ARN for API pods (IRSA)"
  value       = aws_iam_role.api_irsa.arn
}
