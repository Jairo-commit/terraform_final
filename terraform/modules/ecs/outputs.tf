# What the ecs module exposes to the outside (module.ecs.<name>)
output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "instance_id" {
  value = aws_instance.ecs.id
}
