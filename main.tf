provider "aws" {
  region = "il-central-1"
}

locals {
  subnets = [
    "subnet-088b7d937a4cd5d85",
    "subnet-01e6348062924d048",
  ]
}

# Use one subnet to retrieve VPC ID
data "aws_subnet" "subnet_1" {
  id = local.subnets[0]
}

# Reference existing ECS cluster
data "aws_ecs_cluster" "existing_cluster" {
  cluster_name = "imtech"
}

# Reference existing ALB
data "aws_lb" "existing_lb" {
  name = "imtec"
}

# Create the CloudWatch Log Group
resource "aws_cloudwatch_log_group" "nginx_logs" {
  name              = "/ecs/nginx-logs-oleg"
  retention_in_days = 7  # Optional: Set retention policy (e.g., 7 days)
}

# Recreate the missing target group
resource "aws_lb_target_group" "nginx_target_group" {
  name        = "nginx-target-group-oleg"
  port        = 100
  protocol    = "HTTP"
  vpc_id      = data.aws_subnet.subnet_1.vpc_id
  target_type = "ip"

  health_check {
    protocol = "HTTP"
    port     = "100"
    path     = "/"
  }
}

# Create listener on port 100 (if not already created)
resource "aws_lb_listener" "nginx_listener" {
  load_balancer_arn = data.aws_lb.existing_lb.arn
  port              = 100
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }
}

# Task Definition using ECR image
resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-task-oleg-tf"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::314525640319:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([{
    name      = "nginx"
    image     = "314525640319.dkr.ecr.il-central-1.amazonaws.com/imtech-oleg:latest"
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }
    ]
        logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/nginx-logs"
        "awslogs-region"        = "il-central-1"
        "awslogs-stream-prefix" = "nginx"
      }
    }
  }])
}

# ECS Service using the recreated target group
resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-service-oleg"
  cluster         = data.aws_ecs_cluster.existing_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.subnets
    security_groups = ["sg-0ac3749215afde82a"]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.nginx_listener
  ]
}
