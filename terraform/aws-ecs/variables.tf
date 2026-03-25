# --------------------------------------------------
# Variables
# --------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
  default     = "prod"
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

# --- ACM / TLS ---

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS. Leave empty to use HTTP only."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the deployment (used in ALB listener rules)"
  type        = string
  default     = ""
}

# --- RDS ---

variable "rds_instance_class" {
  description = "RDS instance class for Temporal's Postgres database"
  type        = string
  default     = "db.t4g.medium"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 20
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

# --- DynamoDB ---

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode: PROVISIONED or PAY_PER_REQUEST"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_read_capacity" {
  description = "DynamoDB read capacity (only used if billing_mode is PROVISIONED)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "DynamoDB write capacity (only used if billing_mode is PROVISIONED)"
  type        = number
  default     = 5
}

# --- ECS ---

variable "api_cpu" {
  description = "CPU units for the API task (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "api_memory" {
  description = "Memory in MiB for the API task"
  type        = number
  default     = 1024
}

variable "api_desired_count" {
  description = "Desired number of API tasks"
  type        = number
  default     = 2
}

variable "worker_cpu" {
  description = "CPU units for the worker task"
  type        = number
  default     = 1024
}

variable "worker_memory" {
  description = "Memory in MiB for the worker task"
  type        = number
  default     = 2048
}

variable "worker_desired_count" {
  description = "Desired number of worker tasks"
  type        = number
  default     = 2
}

variable "ui_cpu" {
  description = "CPU units for the UI task"
  type        = number
  default     = 512
}

variable "ui_memory" {
  description = "Memory in MiB for the UI task"
  type        = number
  default     = 1024
}

variable "ui_desired_count" {
  description = "Desired number of UI tasks"
  type        = number
  default     = 2
}

variable "temporal_cpu" {
  description = "CPU units for the Temporal server task"
  type        = number
  default     = 1024
}

variable "temporal_memory" {
  description = "Memory in MiB for the Temporal server task"
  type        = number
  default     = 2048
}

variable "temporal_ui_cpu" {
  description = "CPU units for the Temporal UI task"
  type        = number
  default     = 256
}

variable "temporal_ui_memory" {
  description = "Memory in MiB for the Temporal UI task"
  type        = number
  default     = 512
}

# --- Secrets ---

variable "api_bearer_token" {
  description = "Bearer token for API authentication (stored in Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub personal access token for the worker"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitlab_token" {
  description = "GitLab personal access token for the worker"
  type        = string
  sensitive   = true
  default     = ""
}

variable "anthropic_api_key" {
  description = "Anthropic API key for LLM access. Leave empty if using Bedrock."
  type        = string
  sensitive   = true
  default     = ""
}

variable "use_bedrock" {
  description = "Use AWS Bedrock instead of Anthropic API for LLM access"
  type        = bool
  default     = false
}

# --- Logging ---

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}
