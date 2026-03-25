# --------------------------------------------------
# Outputs
# --------------------------------------------------

output "instance_public_ip" {
  description = "Public IP (Elastic IP) of the instance"
  value       = aws_eip.instance.public_ip
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh ubuntu@${aws_eip.instance.public_ip}"
}

output "ui_url" {
  description = "RepoSwarm UI URL"
  value       = "http://${aws_eip.instance.public_ip}"
}

output "api_url" {
  description = "RepoSwarm API URL"
  value       = "http://${aws_eip.instance.public_ip}/v1/health"
}

output "dynamodb_table_name" {
  description = "DynamoDB cache table name"
  value       = aws_dynamodb_table.cache.name
}
