# =============================================================================
#  State bookkeeping (no infrastructure here)
# =============================================================================
#  The real resources were created by the flat version (branch main), so in the
#  S3 state they are stored as e.g. "aws_vpc.main". Inside a module the address
#  becomes "module.network.aws_vpc.main". Without these blocks Terraform would
#  think: "aws_vpc.main is gone -> DESTROY it, module.network.aws_vpc.main is
#  new -> CREATE it". "moved" says: same object, new address. Nothing in AWS
#  changes. Data sources are not stored as objects, so they need no "moved".
# =============================================================================

# --- network
moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.main
}
moved {
  from = aws_internet_gateway.main
  to   = module.network.aws_internet_gateway.main
}
moved {
  from = aws_subnet.public_a
  to   = module.network.aws_subnet.public_a
}
moved {
  from = aws_subnet.public_b
  to   = module.network.aws_subnet.public_b
}
moved {
  from = aws_subnet.private_a
  to   = module.network.aws_subnet.private_a
}
moved {
  from = aws_subnet.private_b
  to   = module.network.aws_subnet.private_b
}
moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}
moved {
  from = aws_route_table.private
  to   = module.network.aws_route_table.private
}
moved {
  from = aws_route_table_association.public_a
  to   = module.network.aws_route_table_association.public_a
}
moved {
  from = aws_route_table_association.public_b
  to   = module.network.aws_route_table_association.public_b
}
moved {
  from = aws_route_table_association.private_a
  to   = module.network.aws_route_table_association.private_a
}
moved {
  from = aws_route_table_association.private_b
  to   = module.network.aws_route_table_association.private_b
}

# --- alb
moved {
  from = aws_security_group.alb
  to   = module.alb.aws_security_group.alb
}
moved {
  from = aws_lb.main
  to   = module.alb.aws_lb.main
}
moved {
  from = aws_lb_target_group.app
  to   = module.alb.aws_lb_target_group.app
}
moved {
  from = aws_lb_listener.http
  to   = module.alb.aws_lb_listener.http
}

# --- ecs
moved {
  from = aws_ecs_cluster.main
  to   = module.ecs.aws_ecs_cluster.main
}
moved {
  from = aws_iam_role.ecs_instance
  to   = module.ecs.aws_iam_role.ecs_instance
}
moved {
  from = aws_iam_role_policy_attachment.ecs_instance_ecs
  to   = module.ecs.aws_iam_role_policy_attachment.ecs_instance_ecs
}
moved {
  from = aws_iam_role_policy_attachment.ecs_instance_ssm
  to   = module.ecs.aws_iam_role_policy_attachment.ecs_instance_ssm
}
moved {
  from = aws_iam_instance_profile.ecs_instance
  to   = module.ecs.aws_iam_instance_profile.ecs_instance
}
moved {
  from = aws_security_group.ecs_instance
  to   = module.ecs.aws_security_group.ecs_instance
}
moved {
  from = aws_instance.ecs
  to   = module.ecs.aws_instance.ecs
}
moved {
  from = aws_ecs_task_definition.app
  to   = module.ecs.aws_ecs_task_definition.app
}
moved {
  from = aws_ecs_service.app
  to   = module.ecs.aws_ecs_service.app
}
moved {
  from = aws_appautoscaling_target.ecs_service
  to   = module.ecs.aws_appautoscaling_target.ecs_service
}
moved {
  from = aws_appautoscaling_policy.ecs_cpu
  to   = module.ecs.aws_appautoscaling_policy.ecs_cpu
}

# --- pipeline
moved {
  from = aws_ecr_repository.app
  to   = module.pipeline.aws_ecr_repository.app
}
moved {
  from = aws_s3_bucket.artifacts
  to   = module.pipeline.aws_s3_bucket.artifacts
}
moved {
  from = aws_s3_bucket_public_access_block.artifacts
  to   = module.pipeline.aws_s3_bucket_public_access_block.artifacts
}
moved {
  from = aws_iam_role.codebuild
  to   = module.pipeline.aws_iam_role.codebuild
}
moved {
  from = aws_iam_role_policy.codebuild
  to   = module.pipeline.aws_iam_role_policy.codebuild
}
moved {
  from = aws_codebuild_project.build
  to   = module.pipeline.aws_codebuild_project.build
}
moved {
  from = aws_iam_role.codepipeline
  to   = module.pipeline.aws_iam_role.codepipeline
}
moved {
  from = aws_iam_role_policy.codepipeline
  to   = module.pipeline.aws_iam_role_policy.codepipeline
}
moved {
  from = aws_codepipeline.pipeline
  to   = module.pipeline.aws_codepipeline.pipeline
}

# --- Old one-time cleanup (from main): the GitHub connection was removed from
#     the state WITHOUT deleting it in AWS. Kept here for history; it is a
#     no-op now. "removed" can only point to root addresses.
removed {
  from = aws_codestarconnections_connection.github

  lifecycle {
    destroy = false
  }
}
