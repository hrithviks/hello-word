####################################
# Application Load Balancer Module #
####################################

variable "alb_name" {
  description = "Name of the ALB"
  type        = string
}

variable "alb_internal_flag" {
  description = "Set to true if the ALB is internal"
  type        = bool
}

variable "alb_type" {
  description = "Type of the ALB (application or network)"
  type        = string
}

variable "alb_sg_ids" {
  description = "List of security group IDs for the ALB"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_tags" {
  description = "A map of tags to assign to the ALB"
  type        = map(string)
  default     = {}
}

variable "alb_target_group_name" {
  description = "Name of the ALB target group"
  type        = string
}

variable "alb_target_group_port" {
  description = "Port for the ALB target group"
  type        = number
}

variable "alb_target_group_protocol" {
  description = "Protocol for the ALB target group"
  type        = string
}

variable "alb_target_group_type" {
  description = "Type of target group (instance, ip, or lambda)"
  type        = string
}

variable "alb_target_group_vpc_id" {
  description = "VPC ID for the ALB target group"
  type        = string
}

variable "alb_target_group_health_check_enabled" {
  description = "Whether health checks are enabled for the target group"
  type        = bool
  default     = true
}

variable "alb_target_group_health_check_interval" {
  description = "Interval between health checks"
  type        = number
  default     = 30 # Interval is set to 30 seconds by default
}

variable "alb_target_group_health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/"
}


variable "alb_target_group_health_check_port" {
  description = "Port for health checks"
  type        = string
  default     = "traffic-port"
}

variable "alb_target_group_health_check_protocol" {
  description = "Protocol for health checks"
  type        = string
  default     = "HTTP"
}

variable "alb_target_group_health_check_timeout" {
  description = "Timeout for health checks"
  type        = number
  default     = 5
}

variable "alb_target_group_health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks to consider the target healthy"
  type        = number
  default     = 5
}

variable "alb_target_group_health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks to consider the target unhealthy"
  type        = number
  default     = 2
}

variable "alb_target_group_health_check_matcher" {
  description = "Matcher for successful health checks"
  type        = string
  default     = "200"
}

variable "alb_listener_port" {
  description = "Port for the ALB listener"
  type        = number
}

variable "alb_listener_protocol" {
  description = "Protocol for the ALB listener"
  type        = string
}

variable "alb_listener_default_action_type" {
  description = "Default action type for the ALB listener"
  type        = string
}
