####################################
# Elastic Container Service Module #
####################################

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_name
  tags = var.ecs_tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.ecs_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.ecs_name}-container"
      image     = var.ecs_container_image
      essential = true
      portMappings = [
        {
          containerPort = var.ecs_container_port
          hostPort      = var.ecs_host_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.ecs_cloudwatch_log_group_name
          "awslogs-region"        = var.ecs_aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service Definition
resource "aws_ecs_service" "main" {
  name            = "${var.ecs_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [var.ecs_task_security_group_id]
    assign_public_ip = var.ecs_assign_public_ip
  }

  load_balancer {
    target_group_arn = var.ecs_target_group_arn
    container_name   = "${var.ecs_name}-container"
    container_port   = var.ecs_container_port
  }
}
