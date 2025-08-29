variable "ecs_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_subnet_ids" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)
}

variable "ecs_container_image" {
  description = "The Docker image to use for the container"
  type        = string
}

variable "ecs_container_port" {
  description = "The port to expose on the container"
  type        = number
}

variable "ecs_host_port" {
  description = "The port to expose on the host"
  type        = number
}

variable "ecs_cpu" {
  description = "The CPU units to allocate to the container"
  type        = string
  default     = "256"
}

variable "ecs_memory" {
  description = "The memory to allocate to the container"
  type        = string
  default     = "512"
}

variable "ecs_desired_count" {
  description = "The desired number of tasks to run"
  type        = number
  default     = 1
}

variable "ecs_assign_public_ip" {
  description = "Whether to assign a public IP to the tasks"
  type        = bool
  default     = true
}

variable "ecs_target_group_arn" {
  description = "ARN of the target group to associate with the service"
  type        = string
}

variable "ecs_aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecs_cloudwatch_log_group_name" {
  description = "Name of the Cloudwatch log group"
  type        = string
}

variable "ecs_task_security_group_id" {
  description = "ID of the security group for the ECS tasks"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ARN of the IAM role for the ECS task execution"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the IAM role for the ECS task"
  type        = string
  default     = null
}

variable "ecs_tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
