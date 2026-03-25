# --------------------------------------------------
# Helm Release for RepoSwarm
# --------------------------------------------------

resource "helm_release" "reposwarm" {
  name      = "reposwarm"
  namespace = "reposwarm"
  chart     = var.helm_chart_path
  version   = "0.1.0"

  create_namespace = true

  # Core configuration
  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "aws.dynamodbTable"
    value = aws_dynamodb_table.cache.name
  }

  # RDS configuration for Temporal
  set {
    name  = "temporal.postgres.host"
    value = split(":", aws_db_instance.temporal.endpoint)[0]
  }

  set {
    name  = "temporal.postgres.port"
    value = "5432"
  }

  set {
    name  = "temporal.postgres.user"
    value = "temporal"
  }

  set_sensitive {
    name  = "temporal.postgres.password"
    value = random_password.rds_password.result
  }

  # Use external RDS — disable in-cluster postgres
  set {
    name  = "postgres.enabled"
    value = "false"
  }

  # IRSA annotations
  set {
    name  = "api.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.api_irsa.arn
  }

  set {
    name  = "worker.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.worker_irsa.arn
  }

  set {
    name  = "ui.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ui_irsa.arn
  }

  # Secrets
  set_sensitive {
    name  = "secrets.apiBearerToken"
    value = var.api_bearer_token
  }

  set_sensitive {
    name  = "secrets.githubToken"
    value = var.github_token
  }

  set_sensitive {
    name  = "secrets.gitlabToken"
    value = var.gitlab_token
  }

  set_sensitive {
    name  = "secrets.anthropicApiKey"
    value = var.anthropic_api_key
  }

  set {
    name  = "worker.useBedrock"
    value = tostring(var.use_bedrock)
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_dynamodb_table.cache,
    aws_db_instance.temporal,
  ]
}
