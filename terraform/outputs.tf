# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "pipeline_name" {
  value = aws_codepipeline.pipeline.name
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "github_connection_status" {
  description = "PENDING until you approve it in the console"
  value       = aws_codestarconnections_connection.github.connection_status
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_instance_id" {
  value = aws_instance.ecs.id
}

output "app_url" {
  description = "Open this in the browser to see index.html (through the ALB)"
  value       = "http://${aws_lb.main.dns_name}"
}
