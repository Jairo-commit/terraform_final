# Inputs of the network module (the root passes them in the "module" block)
variable "project_name" {
  description = "Prefix used to name all resources"
  type        = string
}

variable "aws_region" {
  description = "Region, used to build the AZ names (us-east-1a, us-east-1b)"
  type        = string
}
