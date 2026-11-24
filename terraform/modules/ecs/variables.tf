# Inputs of the ecs module
variable "project_name" {
  description = "Prefix used to name all resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the ECS cluster"
  type        = string
}

variable "container_name" {
  description = "Container name, must match imagedefinitions.json"
  type        = string
}

# --- Coming from module.network ---------------------------------------------
variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  description = "Public subnet where the EC2 instance runs"
  type        = string
}

# --- Coming from module.alb -------------------------------------------------
variable "alb_security_group_id" {
  description = "Only this security group can reach the containers"
  type        = string
}

variable "target_group_arn" {
  type = string
}

variable "listener_arn" {
  description = "Only used to wait for the listener before creating the service"
  type        = string
}

# --- Coming from module.pipeline --------------------------------------------
variable "ecr_repository_url" {
  description = "Image used by the task definition (:latest)"
  type        = string
}
