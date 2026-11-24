# ---------------------------------------------------------------------------
# ECS: cluster backed by ONE EC2 instance, running the web image from ECR
# ---------------------------------------------------------------------------

# 1) The cluster (just a logical group; it is ready in seconds)
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

# 2) Official ECS-optimized Amazon Linux 2023 AMI (Docker + ECS agent included,
#    so no custom AMI or snapshot is needed). AWS publishes its ID in SSM.
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# 3) IAM role for the EC2 instance
#    - AmazonEC2ContainerServiceforEC2Role: register in the cluster, pull from ECR
#    - AmazonSSMManagedInstanceCore: connect with Session Manager (no SSH key)
resource "aws_iam_role" "ecs_instance" {
  name = "${var.project_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ecs" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 can't use a role directly: it needs an "instance profile" that wraps it
resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

# 4) Security group: ONLY the ALB can reach the containers.
#    Containers get a random host port (dynamic port mapping), so we open the
#    Linux ephemeral port range, and only for traffic coming from the ALB SG.
#    Nobody can reach the instance directly from the internet.
resource "aws_security_group" "ecs_instance" {
  name        = "${var.project_name}-ecs-instance-sg"
  description = "HTTP to the ECS instance" # changing it would force a replacement
  vpc_id      = var.vpc_id

  ingress {
    description     = "Dynamic container ports, only from the ALB"
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-instance-sg"
  }
}

# 5) The EC2 instance. user_data tells the ECS agent which cluster to join.
#    It goes in a PUBLIC subnet so it can reach ECS/ECR (there is no NAT).
resource "aws_instance" "ecs" {
  ami                    = data.aws_ssm_parameter.ecs_ami.insecure_value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ecs_instance.id]
  iam_instance_profile   = aws_iam_instance_profile.ecs_instance.name

  user_data = <<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOT

  tags = {
    Name = "${var.project_name}-ecs-node"
  }
}

# 6) Task definition: WHAT to run (the container from ECR, port 80)
#    The container name must match "name" in imagedefinitions.json ("Main").
#    Small task: 0.1 vCPU (102 CPU units) and 0.125 GB (128 MiB).
#    hostPort = 0 -> dynamic port: ECS picks a free port on the instance, so
#    up to 4 copies fit on the same EC2 and the ALB finds them automatically.
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = "${var.ecr_repository_url}:latest"
    cpu       = 102
    memory    = 128
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 0
      protocol      = "tcp"
    }]
  }])
}

# 7) Service: keeps the tasks running and registers them in the ALB target group
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "EC2"

  # Each task is registered automatically as a target (instance + dynamic port)
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = 80
  }

  # Give a new task 30s to start before the ALB health checks count
  health_check_grace_period_seconds = 30

  # Rolling deploy with no downtime: new tasks start first (up to 200%),
  # old ones stop only when the new ones are healthy (never below 100%).
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # Auto scaling (section 8) changes desired_count; don't let Terraform undo it
  lifecycle {
    ignore_changes = [desired_count]
  }

  # The listener must exist before the service registers targets.
  # The listener lives in another module, so we can't write aws_lb_listener.http
  # here: we wait for the input variable that carries its ARN instead.
  depends_on = [var.listener_arn]
}

# 8) Service Auto Scaling: min 2, max 4 tasks
resource "aws_appautoscaling_target" "ecs_service" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 2
  max_capacity       = 4
}

# Target tracking: add tasks when average CPU > 50%, remove them when it drops
resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.project_name}-cpu-target"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = 50
    scale_out_cooldown = 60
    scale_in_cooldown  = 120

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
