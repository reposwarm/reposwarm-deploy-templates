# --------------------------------------------------
# DynamoDB Table — RepoSwarm Cache
# --------------------------------------------------

resource "aws_dynamodb_table" "cache" {
  name         = "${local.name_prefix}-cache"
  billing_mode = var.dynamodb_billing_mode

  # Only set capacity if PROVISIONED
  read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_read_capacity : null
  write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_write_capacity : null

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
