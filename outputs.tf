#------------------------------------------------------------------------------
# AWS ECS SERVICE
#------------------------------------------------------------------------------
output "aws_ecs_service_service_id" {
  description = "The Amazon Resource Name (ARN) that identifies the service."
  value       = aws_ecs_service.service.id
}

output "aws_ecs_service_service_name" {
  description = "The name of the service."
  value       = aws_ecs_service.service.name
}

output "aws_ecs_service_service_cluster" {
  description = "The Amazon Resource Name (ARN) of cluster which the service runs on."
  value       = aws_ecs_service.service.cluster
}

output "aws_ecs_service_service_desired_count" {
  description = "The number of instances of the task definition"
  value       = aws_ecs_service.service.desired_count
}
