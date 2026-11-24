# What the alb module exposes to the outside (module.alb.<name>)
output "security_group_id" {
  description = "The ECS instance only accepts traffic from this security group"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "listener_arn" {
  description = "The ECS service must wait for the listener (see modules/ecs)"
  value       = aws_lb_listener.http.arn
}

output "dns_name" {
  value = aws_lb.main.dns_name
}
