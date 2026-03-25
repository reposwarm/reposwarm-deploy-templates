# --------------------------------------------------
# IAM Roles for Service Accounts (IRSA)
# --------------------------------------------------

locals {
  oidc_provider_url = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

# --- API IRSA Role ---

resource "aws_iam_role" "api_irsa" {
  name = "${local.name_prefix}-api-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:reposwarm:reposwarm-api"
        }
      }
    }]
  })

  tags = {
    Name = "${local.name_prefix}-api-irsa"
  }
}

resource "aws_iam_role_policy" "api_irsa_dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.api_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = [
        aws_dynamodb_table.cache.arn,
        "${aws_dynamodb_table.cache.arn}/index/*"
      ]
    }]
  })
}

# --- Worker IRSA Role ---

resource "aws_iam_role" "worker_irsa" {
  name = "${local.name_prefix}-worker-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:reposwarm:reposwarm-worker"
        }
      }
    }]
  })

  tags = {
    Name = "${local.name_prefix}-worker-irsa"
  }
}

resource "aws_iam_role_policy" "worker_irsa_dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.worker_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = [
        aws_dynamodb_table.cache.arn,
        "${aws_dynamodb_table.cache.arn}/index/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "worker_irsa_bedrock" {
  count = var.use_bedrock ? 1 : 0

  name = "bedrock-access"
  role = aws_iam_role.worker_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ]
      Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.*"
    }]
  })
}

# --- UI IRSA Role ---

resource "aws_iam_role" "ui_irsa" {
  name = "${local.name_prefix}-ui-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:reposwarm:reposwarm-ui"
        }
      }
    }]
  })

  tags = {
    Name = "${local.name_prefix}-ui-irsa"
  }
}

resource "aws_iam_role_policy" "ui_irsa_dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.ui_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = [
        aws_dynamodb_table.cache.arn,
        "${aws_dynamodb_table.cache.arn}/index/*"
      ]
    }]
  })
}
