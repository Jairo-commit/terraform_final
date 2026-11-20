variable "aws_region" {
  description = "Region where everything is created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name all resources"
  type        = string
  default     = "terraform-final"
}

variable "github_repo" {
  description = "GitHub repository the pipeline reads from (owner/name)"
  type        = string
  default     = "Jairo-commit/terraform_final"
}

variable "github_connection_name" {
  description = "Existing, AVAILABLE GitHub connection (not managed by Terraform)"
  type        = string
  default     = "terraform-final-github"
}

variable "github_branch" {
  description = "Branch that triggers the pipeline"
  type        = string
  default     = "main"
}

variable "container_name" {
  description = "Container name written in imagedefinitions.json (used later by ECS deploy)"
  type        = string
  default     = "Main"
}

variable "instance_type" {
  description = "EC2 instance type for the ECS cluster (free tier: t3.small / t3.micro)"
  type        = string
  default     = "t3.small"
}
