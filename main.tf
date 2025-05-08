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
resource "aws_cloudwatch_log_group" "flask_integration_logs_oleg" {
  name              = "/ecs/flask-integration-logs-oleg"
  retention_in_days = 7
}

# Corrected target group with port 5000
resource "aws_lb_target_group" "flask_target_group" {
  name        = "flask-target-group-oleg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_subnet.subnet_1.vpc_id
  target_type = "ip"

  health_check {
    protocol = "HTTP"
    port     = "5000"
    path     = "/"
  }
}

# Listener on ALB pointing to target group
resource "aws_lb_listener" "flask_integration_listener" {
  load_balancer_arn = data.aws_lb.existing_lb.arn
  port              = 5000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_target_group.arn
  }
}

# Task definition referencing correct image and port
resource "aws_ecs_task_definition" "flask_task" {
  family                   = "flask-integration-task-oleg-tf"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::314525640319:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([{
    name      = "flask"
    image     = "314525640319.dkr.ecr.il-central-1.amazonaws.com/imtech-oleg:${BUILD_NUMBER}"
    essential = true
    portMappings = [
      {
        containerPort = 5000
        hostPort      = 5000
        protocol      = "tcp"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/flask-integration-logs-oleg"
        awslogs-region        = "il-central-1"
        awslogs-stream-prefix = "flask"
      }
    }
  }])
}

# ECS service referencing correct port and target group
resource "aws_ecs_service" "flask_service" {
  name            = "flask-service-oleg"
  cluster         = data.aws_ecs_cluster.existing_cluster.id
  task_definition = aws_ecs_task_definition.flask_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.subnets
    security_groups = ["sg-0ac3749215afde82a"]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.flask_target_group.arn
    container_name   = "flask"
    container_port   = 5000
  }

  depends_on = [
    aws_lb_listener.flask_integration_listener
  ]
}
