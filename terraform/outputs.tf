# ---------------------------------------------------------------------------
# Outputs - the root can only read what each module exports
# ---------------------------------------------------------------------------
output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "ecr_repository_url" {
  value = module.pipeline.ecr_repository_url
}

output "pipeline_name" {
  value = module.pipeline.pipeline_name
}

output "artifacts_bucket" {
  value = module.pipeline.artifacts_bucket
}

output "github_connection_status" {
  description = "Must be AVAILABLE for the pipeline Source stage to work"
  value       = module.pipeline.github_connection_status
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_instance_id" {
  value = module.ecs.instance_id
}

output "app_url" {
  description = "Open this in the browser to see index.html (through the ALB)"
  value       = "http://${module.alb.dns_name}"
}
