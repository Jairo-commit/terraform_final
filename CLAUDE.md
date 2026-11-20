# terraform_final

## Goal
Student project: build a professional AWS infrastructure with Terraform, step by step.
The repo holds both the app (`Dockerfile` = httpd + `index.html`, based on class repo
`Jairo-commit/terraform_clase8`) and the Terraform code (`terraform/`).
The app is delivered by an AWS CodePipeline that reads this GitHub repo.

## Rules
- Always the **simplest structure** that works. No extra directories/modules unless asked.
- **One step at a time**: the student checks every step in AWS before the next one.
- Free tier first (e.g. `BUILD_GENERAL1_SMALL`, `t3.small`/`t3.micro`).
- All Terraform lives in `terraform/`, one file per topic:
  `versions.tf` (provider + S3 backend), `variables.tf`, `main.tf` (shared data sources),
  `network.tf` (VPC, subnets, IGW, routes), `pipeline.tf` (connection, ECR, artifacts bucket,
  CodeBuild, CodePipeline + their IAM), `alb.tf` (ALB, target group, listener),
  `ecs.tf` (cluster, instance, task, service, auto scaling), `outputs.tf`.
- State lives only in S3 bucket `terraform-final-state` (backend in `versions.tf`,
  created manually with versioning). Never commit `*.tfstate` or `.terraform/`.
- Build commands (buildspec) are written inline in `aws_codebuild_project`, no buildspec file.
- Don't commit/push or apply for the student unless asked; give the commands.

## Roadmap
1. [x] CodePipeline with 2 stages: **Source** (GitHub connection) -> **Build**
       (CodeBuild: docker build `index.html` image -> push to ECR -> `imagedefinitions.json`).
2. [x] Amazon ECS cluster backed by one EC2 instance (ECS-optimized AMI, t3.small) - `ecs.tf`.
3. [x] Task definition + service, and a **Deploy** stage (ECS) using `imagedefinitions.json`.
   Pipeline stages: Source -> Build -> **Approval** (manual, mandatory) -> Deploy.
4. [x] Public ALB + target group (instance type, dynamic ports on EC2 - no Fargate allowed),
       health check `/`, app reachable only through the ALB - `alb.tf`.
5. [x] ECS Service Auto Scaling: min 2, desired 2, max 4 (CPU target tracking 50%).
   Tasks are small: 0.1 vCPU (102 units) / 0.125 GB (128 MiB). Everything in public subnets.

## Manual steps (cannot be done by Terraform)
- The GitHub connection `terraform-final-github` is NOT managed by Terraform (read with a
  data source, var `github_connection_name`) so it survives destroy and stays AVAILABLE.
  Only if it is ever deleted: create it in Console -> CodePipeline -> Settings -> Connections.
- After a destroy + apply: approve the first pipeline run (Approval stage) so ECR gets an image.
