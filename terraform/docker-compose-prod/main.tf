# --------------------------------------------------
# RepoSwarm — Docker Compose Production (VM/VPS)
# --------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "reposwarm"
      ManagedBy = "terraform"
    }
  }
}

locals {
  name_prefix = "reposwarm-${var.environment}"
}

# --- Data Sources ---

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-*"]
  }

  filter {
    name   = "architecture"
    values = [var.instance_arch == "arm64" ? "arm64" : "x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- VPC (simple — single public subnet) ---

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group ---

resource "aws_security_group" "instance" {
  name_prefix = "${local.name_prefix}-instance-"
  description = "Security group for RepoSwarm VM"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-instance-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- DynamoDB ---

resource "aws_dynamodb_table" "cache" {
  name         = "${local.name_prefix}-cache"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "pk"

  attribute {
    name = "pk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${local.name_prefix}-cache"
  }
}

# --- IAM Instance Profile ---

resource "aws_iam_role" "instance" {
  name = "${local.name_prefix}-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${local.name_prefix}-instance-role"
  }
}

resource "aws_iam_role_policy" "instance_dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.instance.id

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

resource "aws_iam_role_policy" "instance_bedrock" {
  count = var.use_bedrock ? 1 : 0

  name = "bedrock-access"
  role = aws_iam_role.instance.id

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

resource "aws_iam_role_policy" "instance_secrets" {
  name = "secrets-access"
  role = aws_iam_role.instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${local.name_prefix}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "instance" {
  name = "${local.name_prefix}-instance"
  role = aws_iam_role.instance.name

  tags = {
    Name = "${local.name_prefix}-instance-profile"
  }
}

# --- Secrets Manager ---

resource "aws_secretsmanager_secret" "api_bearer_token" {
  name = "${local.name_prefix}/api-bearer-token"

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

  name = "${local.name_prefix}/github-token"

  tags = {
    Name = "${local.name_prefix}-github-token"
  }
}

resource "aws_secretsmanager_secret_version" "github_token" {
  count = var.github_token != "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.github_token[0].id
  secret_string = var.github_token
}

resource "aws_secretsmanager_secret" "anthropic_api_key" {
  count = var.anthropic_api_key != "" ? 1 : 0

  name = "${local.name_prefix}/anthropic-api-key"

  tags = {
    Name = "${local.name_prefix}-anthropic-api-key"
  }
}

resource "aws_secretsmanager_secret_version" "anthropic_api_key" {
  count = var.anthropic_api_key != "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.anthropic_api_key[0].id
  secret_string = var.anthropic_api_key
}

# --- EC2 Instance ---

resource "aws_key_pair" "main" {
  count = var.ssh_public_key != "" ? 1 : 0

  key_name   = "${local.name_prefix}-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${local.name_prefix}-key"
  }
}

resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = aws_iam_instance_profile.instance.name
  key_name               = var.ssh_public_key != "" ? aws_key_pair.main[0].key_name : null

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    aws_region          = var.aws_region
    dynamodb_table      = aws_dynamodb_table.cache.name
    environment         = var.environment
    api_token_secret    = aws_secretsmanager_secret.api_bearer_token.name
    github_token_secret = var.github_token != "" ? aws_secretsmanager_secret.github_token[0].name : ""
    anthropic_secret    = var.anthropic_api_key != "" ? aws_secretsmanager_secret.anthropic_api_key[0].name : ""
    use_bedrock         = var.use_bedrock
  })

  tags = {
    Name = "${local.name_prefix}-instance"
  }
}

resource "aws_eip" "instance" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = "${local.name_prefix}-eip"
  }
}
