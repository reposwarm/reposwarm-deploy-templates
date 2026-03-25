# --------------------------------------------------
# Secrets Manager
# --------------------------------------------------

resource "aws_secretsmanager_secret" "api_bearer_token" {
  name        = "${local.name_prefix}/api-bearer-token"
  description = "API bearer token for RepoSwarm authentication"

  tags = {
    Name = "${local.name_prefix}-api-bearer-token"
  }
}

resource "aws_secretsmanager_secret_version" "api_bearer_token" {
  secret_id     = aws_secretsmanager_secret.api_bearer_token.id
  secret_string = var.api_bearer_token
}

resource "aws_secretsmanager_secret" "github_token" {
  count = var.github_token != "" ? 1 : 0

  name        = "${local.name_prefix}/github-token"
  description = "GitHub personal access token for the worker"

  tags = {
    Name = "${local.name_prefix}-github-token"
  }
}

resource "aws_secretsmanager_secret_version" "github_token" {
  count = var.github_token != "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.github_token[0].id
  secret_string = var.github_token
}

resource "aws_secretsmanager_secret" "gitlab_token" {
  count = var.gitlab_token != "" ? 1 : 0

  name        = "${local.name_prefix}/gitlab-token"
  description = "GitLab personal access token for the worker"

  tags = {
    Name = "${local.name_prefix}-gitlab-token"
  }
}

resource "aws_secretsmanager_secret_version" "gitlab_token" {
  count = var.gitlab_token != "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.gitlab_token[0].id
  secret_string = var.gitlab_token
}

resource "aws_secretsmanager_secret" "anthropic_api_key" {
  count = var.anthropic_api_key != "" ? 1 : 0

  name        = "${local.name_prefix}/anthropic-api-key"
  description = "Anthropic API key for LLM access"

  tags = {
    Name = "${local.name_prefix}-anthropic-api-key"
  }
}

resource "aws_secretsmanager_secret_version" "anthropic_api_key" {
  count = var.anthropic_api_key != "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.anthropic_api_key[0].id
  secret_string = var.anthropic_api_key
}
