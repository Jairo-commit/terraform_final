# What the pipeline module exposes to the outside (module.pipeline.<name>)
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
  description = "Must be AVAILABLE for the pipeline Source stage to work"
  value       = data.aws_codestarconnections_connection.github.connection_status
}
