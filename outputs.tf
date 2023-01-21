# ECS Balancer
output "aws_lb_endpoint" {
  description = "AWS ALB Endpoint"
  value       = element(concat(aws_lb.ecs_fargate_alb.*.dns_name, list("")), 0)
}

output "aws_lb_arn" {
  description = "AWS ALB ARN"
  value       = element(concat(aws_lb.ecs_fargate_alb.*.arn, list("")), 0)
}

output "aws_lb_bucket_name" {
  description = "AWS ALB Bucket Name"
  value       = element(concat(aws_s3_bucket.alb-log-bucket.*.id, list("")), 0)
}

output "aws_ecs_service_name" {
  description = "AWS ECS Service Name"
  value       = element(concat(aws_ecs_service.main.*.name, list("")), 0)
}