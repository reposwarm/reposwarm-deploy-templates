# --------------------------------------------------
# Variables
# --------------------------------------------------

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
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

# --- EKS ---

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["t4g.large"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 6
}

variable "node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 50
}

# --- DynamoDB ---

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

# --- Helm Values ---

variable "helm_chart_path" {
  description = "Path to the RepoSwarm Helm chart (relative to module root)"
  type        = string
  default     = "../../helm/reposwarm"
}

variable "helm_values_file" {
  description = "Path to custom Helm values file (optional)"
  type        = string
  default     = ""
}

# --- Secrets ---

variable "api_bearer_token" {
  description = "Bearer token for API authentication"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitlab_token" {
  description = "GitLab personal access token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "anthropic_api_key" {
  description = "Anthropic API key (leave empty if using Bedrock)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "use_bedrock" {
  description = "Use AWS Bedrock for LLM access"
  type        = bool
  default     = false
}

# --- RDS ---

variable "rds_instance_class" {
  description = "RDS instance class for Temporal Postgres"
  type        = string
  default     = "db.t4g.medium"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to access services. Defaults to VPC CIDR only."
  type        = list(string)
  default     = []
}
