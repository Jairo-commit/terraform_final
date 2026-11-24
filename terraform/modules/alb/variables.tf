# Inputs of the alb module
variable "project_name" {
  description = "Prefix used to name all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC where the ALB, its security group and the target group live"
  type        = string
}

variable "public_subnet_ids" {
  description = "The 2 public subnets of the ALB (an ALB needs 2 AZs)"
  type        = list(string)
}
