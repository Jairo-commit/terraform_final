# ---------------------------------------------------------------------------
# Application Load Balancer: the ONLY public entry point to the app
# ---------------------------------------------------------------------------

# 1) Security group of the ALB: HTTP (80) open to the internet
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "HTTP from the internet to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# 2) The ALB itself: public, in the 2 public subnets (an ALB needs 2 AZs)
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
}

# 3) Target group: where the ALB sends traffic. ECS registers each task here
#    (target type "instance" = EC2 instance + the task's dynamic port).
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  # Wait only 30s for old tasks to finish their requests (default is 300s)
  deregistration_delay = 30

  # Health check: GET / must answer 200, otherwise the target is unhealthy
  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# 4) Listener: ALB port 80 -> forward to the target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
