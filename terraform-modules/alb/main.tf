####################################
# Application Load Balancer Module #
####################################

# Main ALB resource
resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = var.alb_internal_flag
  load_balancer_type = var.alb_type
  security_groups    = var.alb_sg_ids
  subnets            = var.alb_subnet_ids
  tags               = var.alb_tags
}

# ALB target group
resource "aws_lb_target_group" "main" {
  name        = var.alb_target_group_name
  port        = var.alb_target_group_port
  protocol    = var.alb_target_group_protocol
  target_type = var.alb_target_group_type
  vpc_id      = var.alb_target_group_vpc_id

  health_check {
    enabled             = var.alb_target_group_health_check_enabled
    interval            = var.alb_target_group_health_check_interval
    path                = var.alb_target_group_health_check_path
    port                = var.alb_target_group_health_check_port
    protocol            = var.alb_target_group_health_check_protocol
    timeout             = var.alb_target_group_health_check_timeout
    healthy_threshold   = var.alb_target_group_health_check_healthy_threshold
    unhealthy_threshold = var.alb_target_group_health_check_unhealthy_threshold
    matcher             = var.alb_target_group_health_check_matcher
  }
}

# ALB listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_listener_port
  protocol          = var.alb_listener_protocol

  default_action {
    type             = var.alb_listener_default_action_type
    target_group_arn = aws_lb_target_group.main.arn
  }
}
