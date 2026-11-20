# =============================================================================
#  terraform_final - MAIN (read this file first)
# =============================================================================
#  Terraform reads ALL .tf files in this folder as if they were one file.
#  File names are only for humans. The creation order is NOT the order of the
#  files/lines: Terraform builds it from the references between resources
#  (e.g. a subnet uses aws_vpc.main.id -> the VPC is created first).
#
#  Step by step, this is how the infrastructure is built:
#
#  0) versions.tf  - AWS provider + remote state in S3 (terraform-final-state)
#     variables.tf - names and settings used everywhere (region, project_name...)
#
#  1) network.tf   - THE NETWORK
#     1.1 aws_vpc.main                      10.0.0.0/16
#     1.2 aws_internet_gateway.main         door to the internet      (needs 1.1)
#     1.3 aws_subnet.public_a / public_b    10.0.1.0/24, 10.0.2.0/24  (needs 1.1)
#         aws_subnet.private_a / private_b  10.0.11.0/24, 10.0.12.0/24
#     1.4 aws_route_table.public            0.0.0.0/0 -> IGW          (needs 1.2)
#         aws_route_table.private           only local VPC traffic
#     1.5 aws_route_table_association.*     subnet <-> route table    (needs 1.3, 1.4)
#
#  2) pipeline.tf  - THE CI/CD PIPELINE (Release change -> new image in ECR)
#     2.1 aws_codestarconnections_connection.github  GitHub access (approve in console)
#     2.2 aws_ecr_repository.app            where the Docker image is stored
#     2.3 aws_s3_bucket.artifacts           files passed between pipeline stages
#     2.4 aws_iam_role.codebuild (+policy)  permissions: logs, S3, push to ECR (needs 2.2, 2.3)
#     2.5 aws_codebuild_project.build       docker build + push :latest   (needs 2.4)
#     2.6 aws_iam_role.codepipeline (+policy) permissions: S3, GitHub, CodeBuild (needs 2.1, 2.5)
#     2.7 aws_codepipeline.pipeline         Source (GitHub) -> Build (CodeBuild)
#         -> Approval (manual, stops here) -> Deploy (ECS)
#                                           (needs all above AND 4.1 + 4.7:
#                                            cluster and service exist first)
#
#  3) alb.tf       - THE LOAD BALANCER (the only public entry point)
#     3.1 aws_security_group.alb            port 80 open to the internet (needs 1.1)
#     3.2 aws_lb.main                       public ALB in public_a + public_b (needs 1.3, 3.1)
#     3.3 aws_lb_target_group.app           type instance, health check GET / -> 200
#     3.4 aws_lb_listener.http              ALB :80 -> target group     (needs 3.2, 3.3)
#
#  4) ecs.tf       - THE CONTAINERS (where the web page runs)
#     4.1 aws_ecs_cluster.main              the cluster
#     4.2 data.aws_ssm_parameter.ecs_ami    official ECS-optimized AMI (no snapshot)
#     4.3 aws_iam_role.ecs_instance         join the cluster, pull from ECR, SSM
#         (+2 policy attachments, + instance profile)
#     4.4 aws_security_group.ecs_instance   ports 32768-65535 ONLY from the ALB (needs 3.1)
#     4.5 aws_instance.ecs                  t3.small in public_a, joins 4.1
#                                           (needs 1.3, 4.1, 4.2, 4.3, 4.4)
#     4.6 aws_ecs_task_definition.app       "Main", ECR :latest, 0.1 vCPU / 128 MiB,
#                                           dynamic host port            (needs 2.2)
#     4.7 aws_ecs_service.app               2 tasks, registered in the target group
#                                           (needs 4.1, 4.6, 3.3, 3.4)
#     4.8 aws_appautoscaling_target/policy  min 2 / max 4 tasks, CPU 50% (needs 4.7)
#
#  outputs.tf      - values printed after "terraform apply" (IDs, URLs)
# =============================================================================

# Shared data: current AWS account id (used to build unique names, e.g. the bucket)
data "aws_caller_identity" "current" {}
