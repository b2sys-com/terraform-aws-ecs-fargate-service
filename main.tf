#------------------------------------------------------------------------------
# AWS ECS SERVICE
#------------------------------------------------------------------------------
resource "aws_ecs_service" "service" {
  name = "${var.name_prefix}-service"
  # capacity_provider_strategy - (Optional) The capacity provider strategy to use for the service. Can be one or more. Defined below.
  cluster                            = var.ecs_cluster_arn
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  desired_count                      = var.desired_count
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  enable_execute_command             = var.enable_execute_command
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  launch_type                        = "FARGATE"
  force_new_deployment               = var.force_new_deployment

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  network_configuration {
    security_groups  = var.security_groups
    subnets          = var.assign_public_ip ? var.public_subnets : var.private_subnets
    assign_public_ip = var.assign_public_ip
  }
  deployment_circuit_breaker {
    enable   = var.deployment_circuit_breaker_enabled
    rollback = var.deployment_circuit_breaker_rollback
  }
  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = lookup(ordered_placement_strategy.value, "field", null)
    }
  }
  dynamic "deployment_controller" {
    for_each = var.deployment_controller
    content {
      type = deployment_controller.value.type
    }
  }
  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      expression = lookup(placement_constraints.value, "expression", null)
      type       = placement_constraints.value.type
    }
  }
  platform_version = var.platform_version
  propagate_tags   = var.propagate_tags
  dynamic "service_registries" {
    for_each = var.service_registries
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = lookup(service_registries.value, "port", null)
      container_name = lookup(service_registries.value, "container_name", null)
      container_port = lookup(service_registries.value, "container_port", null)
    }
  }
  task_definition = var.task_definition_arn
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ecs-tasks-sg"
    },
  )
}

module "ecs-autoscaling" {
  count = var.enable_autoscaling ? 1 : 0

  source  = "cn-terraform/ecs-service-autoscaling/aws"
  version = "1.0.6"

  name_prefix               = var.name_prefix
  ecs_cluster_name          = var.ecs_cluster_name
  ecs_service_name          = aws_ecs_service.service.name
  max_cpu_threshold         = var.max_cpu_threshold
  min_cpu_threshold         = var.min_cpu_threshold
  max_cpu_evaluation_period = var.max_cpu_evaluation_period
  min_cpu_evaluation_period = var.min_cpu_evaluation_period
  max_cpu_period            = var.max_cpu_period
  min_cpu_period            = var.min_cpu_period
  scale_target_max_capacity = var.scale_target_max_capacity
  scale_target_min_capacity = var.scale_target_min_capacity
  tags                      = var.tags
}
