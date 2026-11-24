# ---------------------------------------------------------------------------
# 1) GitHub connection - NOT managed by Terraform, only READ (data source)
#    A new connection is always born PENDING and needs a manual approval in the
#    console. By keeping it outside Terraform, it survives "terraform destroy"
#    and stays AVAILABLE, so a full destroy + apply needs no manual step.
#    To use another connection (e.g. Connection_clase8), change
#    var.github_connection_name.
# ---------------------------------------------------------------------------
data "aws_codestarconnections_connection" "github" {
  name = var.github_connection_name
}

# Current AWS account id (used to build a unique bucket name)
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# 2) ECR repository where the Docker image (Dockerfile + index.html) is pushed
# ---------------------------------------------------------------------------
resource "aws_ecr_repository" "app" {
  name         = var.project_name
  force_delete = true # allow terraform destroy even if it has images

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ---------------------------------------------------------------------------
# 3) S3 bucket where CodePipeline passes files between stages (artifacts)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project_name}-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # empty the bucket automatically on terraform destroy
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# 4) IAM role for CodeBuild
# ---------------------------------------------------------------------------
resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.project_name}-codebuild-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },
      {
        Sid      = "Artifacts"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "EcrPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# 5) CodeBuild project: builds the image and pushes it to ECR
# ---------------------------------------------------------------------------
resource "aws_codebuild_project" "build" {
  name         = "${var.project_name}-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true # required to run docker build

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.app.repository_url
    }

    environment_variable {
      name  = "ECR_REGISTRY"
      value = split("/", aws_ecr_repository.app.repository_url)[0]
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.container_name
    }
  }

  # Same as the console box "Insert build commands"
  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
        build:
          commands:
            - echo Building the Docker image...
            - docker build -t $REPOSITORY_URI:latest .
        post_build:
          commands:
            - echo Pushing the Docker image...
            - docker push $REPOSITORY_URI:latest
            - printf '[{"name":"%s","imageUri":"%s"}]' $CONTAINER_NAME $REPOSITORY_URI:latest > imagedefinitions.json
            - cat imagedefinitions.json
      artifacts:
        files:
          - imagedefinitions.json
    EOT
  }
}

# ---------------------------------------------------------------------------
# 6) IAM role for CodePipeline
# ---------------------------------------------------------------------------
resource "aws_iam_role" "codepipeline" {
  name = "${var.project_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${var.project_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Artifacts"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [aws_s3_bucket.artifacts.arn, "${aws_s3_bucket.artifacts.arn}/*"]
      },
      {
        Sid      = "GitHubConnection"
        Effect   = "Allow"
        Action   = ["codestar-connections:UseConnection", "codeconnections:UseConnection"]
        Resource = data.aws_codestarconnections_connection.github.arn
      },
      {
        Sid      = "CodeBuild"
        Effect   = "Allow"
        Action   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
        Resource = aws_codebuild_project.build.arn
      },
      {
        Sid    = "EcsDeploy"
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:TagResource",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Sid      = "PassRoleToEcsTasks"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEqualsIfExists = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# 7) CodePipeline: Source (GitHub) -> Build (CodeBuild) -> Approval (manual) -> Deploy (ECS)
# ---------------------------------------------------------------------------
resource "aws_codepipeline" "pipeline" {
  name          = "${var.project_name}-pipeline"
  role_arn      = aws_iam_role.codepipeline.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  # Mandatory manual approval: the pipeline STOPS here until someone clicks
  # "Review -> Approve" in the console. "Reject" stops the run (no deploy).
  # If nobody answers in 7 days, the approval expires and the run fails.
  stage {
    name = "Approval"

    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "New image built in ECR (terraform-final:latest). Approve to deploy it to ECS."
      }
    }
  }

  # Uses the cluster and service names (outputs of module.ecs, passed in as
  # variables) -> Terraform still creates them BEFORE the pipeline
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  # the role must have its permissions before the pipeline runs for the first time
  depends_on = [aws_iam_role_policy.codepipeline]
}
