# References - official docs behind every decision

This file lists the **official documentation** for every Terraform resource and every
design decision in this project, so you can study where each line comes from.

- **HashiCorp** (Terraform language + AWS provider): how to *write* each resource.
- **AWS**: *why* the infrastructure is configured that way.

> Note: only a few of these pages were opened during the build (marked 📖: the
> CodeStar connection, CodePipeline, CodeBuild project and S3 bucket pages, plus the
> AWS buildspec reference). The other links point to the official pages that document
> the same decisions.

---

## 1. Terraform language (HashiCorp)

| Topic | Where it is used | Docs |
|---|---|---|
| Files and folders: Terraform loads **all** `.tf` files in a folder as one configuration | Splitting into `network.tf`, `pipeline.tf`, `alb.tf`, `ecs.tf`... | https://developer.hashicorp.com/terraform/language/files |
| Resource dependencies: creation order comes from **references**, not from file order | Why the cluster and service exist before the pipeline's Deploy stage | https://developer.hashicorp.com/terraform/language/resources/behavior#resource-dependencies |
| `depends_on` | Pipeline waits for its IAM policy; service waits for the listener | https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on |
| `lifecycle { ignore_changes }` | Service ignores `desired_count` (auto scaling owns it) | https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle |
| S3 backend (`use_lockfile`, `encrypt`) | `versions.tf`: state in `terraform-final-state` | https://developer.hashicorp.com/terraform/language/backend/s3 |
| Input variables | `variables.tf` | https://developer.hashicorp.com/terraform/language/values/variables |
| Outputs | `outputs.tf` (`app_url`...) | https://developer.hashicorp.com/terraform/language/values/outputs |
| Data sources | AMI from SSM, account id | https://developer.hashicorp.com/terraform/language/data-sources |
| Heredoc strings (`<<-EOT`) | Inline buildspec, `user_data` | https://developer.hashicorp.com/terraform/language/expressions/strings#heredoc-strings |
| `jsonencode()` | IAM policies, container definitions | https://developer.hashicorp.com/terraform/language/functions/jsonencode |
| `split()` | ECR registry from the repository URL | https://developer.hashicorp.com/terraform/language/functions/split |
| `terraform graph` | Seeing the dependency order | https://developer.hashicorp.com/terraform/cli/commands/graph |
| `-chdir` (run Terraform from another folder) | `terraform -chdir=terraform apply` | https://developer.hashicorp.com/terraform/cli/commands#switching-working-directory-with-chdir |

---

## 2. AWS provider resources (HashiCorp Registry)

Base URL: `https://registry.terraform.io/providers/hashicorp/aws/latest/docs`

### `network.tf`
| Resource | Docs |
|---|---|
| `aws_vpc` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc |
| `aws_internet_gateway` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway |
| `aws_subnet` (`map_public_ip_on_launch`) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet |
| `aws_route_table` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table |
| `aws_route_table_association` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association |

### `pipeline.tf`
| Resource | Docs |
|---|---|
| 📖 `aws_codestarconnections_connection` (created **PENDING**, finish in the console) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_connection |
| `aws_ecr_repository` (`force_delete`, `scan_on_push`) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository |
| 📖 `aws_s3_bucket` (`force_destroy`) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket |
| `aws_s3_bucket_public_access_block` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block |
| `aws_iam_role` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role |
| `aws_iam_role_policy` (inline policy) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy |
| 📖 `aws_codebuild_project` (`buildspec`, `privileged_mode`, `CODEPIPELINE` source) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project |
| 📖 `aws_codepipeline` (`artifact_store` is **required**, stages, `pipeline_type`) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline |
| `aws_caller_identity` (data source) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity |

### `alb.tf`
| Resource | Docs |
|---|---|
| `aws_security_group` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group |
| `aws_lb` (`load_balancer_type = "application"`) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb |
| `aws_lb_target_group` (`target_type`, `health_check`, `deregistration_delay`) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group |
| `aws_lb_listener` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener |

### `ecs.tf`
| Resource | Docs |
|---|---|
| `aws_ecs_cluster` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster |
| `aws_ssm_parameter` (data source, `insecure_value`) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter |
| `aws_iam_role_policy_attachment` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment |
| `aws_iam_instance_profile` | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile |
| `aws_instance` (`user_data`, `iam_instance_profile`) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance |
| `aws_ecs_task_definition` (`network_mode`, `container_definitions`) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition |
| `aws_ecs_service` (`load_balancer`, deployment %, `health_check_grace_period_seconds`) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service |
| `aws_appautoscaling_target` (min 2 / max 4) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target |
| `aws_appautoscaling_policy` (target tracking CPU) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy |

---

## 3. Design decisions and the AWS docs behind them

### CI/CD pipeline
| Decision | Why | Docs |
|---|---|---|
| GitHub through a **CodeStar/CodeConnections** connection, approved once in the console | AWS requires the OAuth handshake to be done by a human | https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-update.html |
| 📖 **Buildspec inline** in the CodeBuild project (no `buildspec.yml`) | A buildspec can be in the repo *or* in the project definition (same as the console's "Insert build commands") | https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html |
| `privileged_mode = true` + `docker login/build/push` | Required to build Docker images inside CodeBuild | https://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html |
| Push to ECR with `aws ecr get-login-password` | Official way to authenticate Docker to ECR | https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html |
| `imagedefinitions.json` with `name` = `Main` | File format the ECS standard deploy action reads | https://docs.aws.amazon.com/codepipeline/latest/userguide/file-reference.html |
| **Deploy** stage with provider `ECS` | Standard ECS deploy action of CodePipeline | https://docs.aws.amazon.com/codepipeline/latest/userguide/ecs-cd-pipeline.html |
| **Manual Approval** stage (pipeline stops, 7-day timeout) | Approval actions in CodePipeline | https://docs.aws.amazon.com/codepipeline/latest/userguide/approvals.html |
| S3 **artifact store** | CodePipeline passes artifacts between stages through S3 | https://docs.aws.amazon.com/codepipeline/latest/userguide/concepts.html |

### ECS on EC2
| Decision | Why | Docs |
|---|---|---|
| **ECS-optimized AMI** from a public SSM parameter (no snapshot/custom AMI) | It already has Docker + the ECS agent, and always gives the latest AMI | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/retrieve-ecs-optimized_AMI.html |
| `user_data`: `ECS_CLUSTER=...` in `/etc/ecs/ecs.config` | How a container instance joins a specific cluster | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bootstrap_container_instance.html |
| Instance role with `AmazonEC2ContainerServiceforEC2Role` | Lets the ECS agent register the instance and pull images from ECR | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance_IAM_role.html |
| `AmazonSSMManagedInstanceCore` (no SSH key) | Connect with Session Manager | https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html |
| `bridge` network mode + `hostPort = 0` (**dynamic port mapping**) | Several copies of the same container on one EC2, each on its own host port | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking-bridge.html |
| No `awsvpc` / IP target group on a `t3.small` | In `awsvpc` mode each task needs its own ENI, and a small instance only has a few, so 4 tasks would not fit | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking-awsvpc.html |
| `cpu = 102`, `memory = 128` | Task size units (1024 CPU units = 1 vCPU; memory in MiB) | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html |
| `deployment_minimum_healthy_percent = 100`, `maximum_percent = 200` | Rolling update: new tasks start before old ones stop (zero downtime) | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-ecs.html |
| Service `load_balancer` block | ECS registers/deregisters each task in the target group automatically | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html |

### Application Load Balancer
| Decision | Why | Docs |
|---|---|---|
| ALB in **2 public subnets** (2 AZs) | An ALB requires subnets in at least two Availability Zones | https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html |
| Target group type `instance` + health check `GET /` → `200` | Health checks decide which targets receive traffic | https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html |
| `deregistration_delay = 30` | Faster deploys (default is 300 s) | https://docs.aws.amazon.com/elasticloadbalancing/latest/application/edit-target-group-attributes.html#deregistration-delay |
| Instance SG only allows ports 32768-65535 **from the ALB SG** | App reachable only through the ALB; dynamic ports need the ephemeral range open | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking-bridge.html |

### ECS Service Auto Scaling
| Decision | Why | Docs |
|---|---|---|
| Min 2 / desired 2 / max 4 with **target tracking** on CPU 50% | Standard way to scale an ECS service | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-autoscaling-targettracking.html |
| General overview | | https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html |

### Network and state
| Decision | Why | Docs |
|---|---|---|
| Public subnet = route `0.0.0.0/0` → Internet Gateway | Definition of a public subnet | https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html |
| No NAT gateway (tasks run in public subnets) | A NAT gateway is billed per hour + per GB | https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html |
| State in S3 with versioning | Recover older state versions | https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html |

---

## 4. Costs

| Item | Docs |
|---|---|
| AWS Free Tier | https://aws.amazon.com/free/ |
| ALB pricing | https://aws.amazon.com/elasticloadbalancing/pricing/ |
| CodePipeline pricing (V2) | https://aws.amazon.com/codepipeline/pricing/ |
| CodeBuild pricing | https://aws.amazon.com/codebuild/pricing/ |
| Public IPv4 pricing | https://aws.amazon.com/vpc/pricing/ |
