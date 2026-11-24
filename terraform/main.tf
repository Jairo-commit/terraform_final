# =============================================================================
#  terraform_final - MAIN (branch: modules-experiment)
# =============================================================================
#  Terraform only reads the .tf files of THIS folder (the root module).
#  The folders in modules/ are ignored UNTIL a "module" block below loads them
#  with "source". After adding/changing a module block -> run "terraform init".
#
#  Each module is a closed box:
#    - IN : it only sees the arguments passed here (its variables.tf)
#    - OUT: the root only sees what it exports (its outputs.tf),
#           read as module.<name>.<output>
#
#  The order of the blocks below does NOT matter either: Terraform still builds
#  ONE graph with all the resources of all the modules. Wiring outputs into
#  inputs is what creates the dependencies:
#
#    network --vpc/subnets--> alb --sg/target group/listener--> ecs
#    pipeline --ecr url--> ecs --cluster/service names--> pipeline
#
#  The last line looks like a loop between modules, but it isn't one between
#  RESOURCES: ECR -> task definition -> service -> CodePipeline. Modules are
#  not created as a block; each resource waits only for what it uses.
# =============================================================================

# 1) THE NETWORK - VPC, 2 public + 2 private subnets, IGW, route tables
module "network" {
  source = "./modules/network"

  project_name = var.project_name
  aws_region   = var.aws_region
}

# 2) THE LOAD BALANCER - the only public entry point
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
}

# 3) THE CONTAINERS - cluster, EC2 instance, task, service, auto scaling
module "ecs" {
  source = "./modules/ecs"

  project_name   = var.project_name
  instance_type  = var.instance_type
  container_name = var.container_name

  vpc_id    = module.network.vpc_id
  subnet_id = module.network.public_subnet_ids[0] # public_a

  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_arn
  listener_arn          = module.alb.listener_arn

  ecr_repository_url = module.pipeline.ecr_repository_url
}

# 4) THE CI/CD PIPELINE - ECR, artifacts bucket, CodeBuild, CodePipeline
module "pipeline" {
  source = "./modules/pipeline"

  project_name           = var.project_name
  github_repo            = var.github_repo
  github_connection_name = var.github_connection_name
  github_branch          = var.github_branch
  container_name         = var.container_name

  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name
}
