# --------------------------------------------------
# DynamoDB Table
# --------------------------------------------------

resource "aws_dynamodb_table" "cache" {
  name         = "${local.name_prefix}-cache"
  billing_mode = var.dynamodb_billing_mode

  hash_key = "pk"

  attribute {
    name = "pk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${local.name_prefix}-cache"
  }
}

# --------------------------------------------------
# RDS Postgres for Temporal
# --------------------------------------------------

resource "aws_db_subnet_group" "temporal" {
  name       = "${local.name_prefix}-temporal-db"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${local.name_prefix}-temporal-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "Security group for Temporal RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.main.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_password" "rds_password" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "rds_password" {
  name        = "${local.name_prefix}/rds-password"
  description = "RDS password for Temporal Postgres"

  tags = {
    Name = "${local.name_prefix}-rds-password"
  }
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.rds_password.result
}

resource "aws_db_instance" "temporal" {
  identifier = "${local.name_prefix}-temporal"

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.rds_instance_class

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_allocated_storage * 2
  storage_encrypted     = true

  db_name  = "temporal"
  username = "temporal"
  password = random_password.rds_password.result

  db_subnet_group_name   = aws_db_subnet_group.temporal.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period   = 7
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name_prefix}-temporal-final"

  tags = {
    Name = "${local.name_prefix}-temporal-db"
  }
}
