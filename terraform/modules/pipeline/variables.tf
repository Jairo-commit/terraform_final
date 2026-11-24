# Inputs of the pipeline module
variable "project_name" {
  description = "Prefix used to name all resources"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository the pipeline reads from (owner/name)"
  type        = string
}

variable "github_connection_name" {
  description = "Existing, AVAILABLE GitHub connection (not managed by Terraform)"
  type        = string
}

variable "github_branch" {
  description = "Branch that triggers the pipeline"
  type        = string
}

variable "container_name" {
  description = "Container name written in imagedefinitions.json"
  type        = string
}

# --- Coming from module.ecs (used by the Deploy stage) ----------------------
variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}
