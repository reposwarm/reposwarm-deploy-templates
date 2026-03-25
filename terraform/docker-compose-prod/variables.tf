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

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone" {
  description = "Single availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.xlarge"
}

variable "instance_arch" {
  description = "Instance architecture: arm64 or x86_64"
  type        = string
  default     = "arm64"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 50
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "api_bearer_token" {
  description = "API bearer token"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub personal access token"
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
