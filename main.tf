resource "aws_ecs_service" "main" {
  count                  = length(var.load_balancer_config)
  name                   = "svc-ecs-${substr(uuid(), 0, 3)}"
  cluster                = var.cluster_id
  task_definition        = lookup(var.fargate_services, "task_definition_arn")
  desired_count          = lookup(var.fargate_services, "service_desired_count", 1)
  launch_type            = "FARGATE"
  enable_execute_command = var.enable_execute_command
  load_balancer {
    target_group_arn = aws_lb_target_group.tg[count.index].arn != null ? aws_lb_target_group.tg[count.index].arn : null
    container_name   = var.container_name
    container_port   = lookup(element(var.load_balancer_config, count.index), "container_port", null) != null ? element(var.load_balancer_config, count.index)["container_port"] : 8080
  }
  network_configuration {
    security_groups  = var.security_group_ids
    subnets          = var.private_subnet_ids
    assign_public_ip = var.assign_public_ip
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
  tags       = var.tags
  depends_on = [aws_lb.ecs_fargate_alb]
}


# AWS S3 Bucket for ALB
resource "random_id" "id" {
  byte_length = 4
}

locals {
  bucket_name     = "${var.container_name}-alb-logs-${random_id.id.dec}"
  bucket_name_arn = "arn:aws:s3:::${local.bucket_name}"
}
data "aws_elb_service_account" "main" {}

data "aws_caller_identity" "current_caller" {}

data "template_file" "ecs-s3-file" {
  template = templatefile("${path.module}/policies/s3/S3BucketPolicy.json", {
    account_id               = data.aws_caller_identity.current_caller.account_id,
    bucket_name_arn          = local.bucket_name_arn,
    aws_balancer_account_arn = data.aws_elb_service_account.main.arn
    }
  )
}

resource "aws_s3_bucket_policy" "lb-bucket-policy" {
  count      = var.access_logs ? 1 : 0
  bucket     = aws_s3_bucket.alb-log-bucket[count.index].id
  policy     = data.template_file.ecs-s3-file.rendered
  depends_on = [data.template_file.ecs-s3-file, aws_s3_bucket.alb-log-bucket]
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [bucket, policy]
  }
}

resource "aws_s3_bucket" "alb-log-bucket" {
  count         = var.access_logs ? 1 : 0
  bucket        = local.bucket_name
  acl           = "private"
  force_destroy = true
}

# AWS ECS Balancer
resource "aws_lb" "ecs_fargate_alb" {
  name               = "alb-${var.fargate_cluster_name}"
  subnets            = var.balancer_allowed_subnet_ids
  load_balancer_type = "application"
  security_groups    = var.balancer_fargate_security_group_ids
  idle_timeout       = var.lb_idle_timeout
  internal           = var.internal
  access_logs {
    bucket  = var.access_logs ? aws_s3_bucket.alb-log-bucket[0].bucket : "null"
    enabled = var.access_logs
  }
  tags       = var.tags
  depends_on = [aws_s3_bucket.alb-log-bucket]
}

resource "aws_lb_listener" "https_redirect" {
  count             = var.redirect_https ? length(aws_lb_target_group.tg) : 0
  load_balancer_arn = aws_lb.ecs_fargate_alb.arn
  port              = lookup(element(var.load_balancer_config, count.index), "lb_listener_port_redirect", null) != null ? element(var.load_balancer_config, count.index)["lb_listener_port_redirect"] : 80
  protocol          = "HTTP"
  default_action {
    type             = "redirect"
    target_group_arn = aws_lb_target_group.tg[count.index].arn
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  depends_on = [aws_lb.ecs_fargate_alb]
}

resource "aws_lb_listener" "https_forward" {
  count             = length(aws_lb_target_group.tg)
  load_balancer_arn = aws_lb.ecs_fargate_alb.arn
  port              = lookup(element(var.load_balancer_config, count.index), "lb_listener_port", null) != null ? element(var.load_balancer_config, count.index)["lb_listener_port"] : 80
  protocol          = lookup(element(var.load_balancer_config, count.index), "lb_listener_protocol", null) != null ? element(var.load_balancer_config, count.index)["lb_listener_protocol"] : "HTTP"
  certificate_arn   = element(var.load_balancer_config, count.index)["lb_listener_protocol"] == "HTTPS" ? var.certificate_arn : null
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[count.index].arn
  }

  depends_on = [aws_lb.ecs_fargate_alb]
}

# AWS ECS Fargate Target Group
resource "aws_lb_target_group" "tg" {
  count       = length(var.load_balancer_config)
  name_prefix = "tg-ecs"
  port        = lookup(element(var.load_balancer_config, count.index), "container_port", null) != null ? element(var.load_balancer_config, count.index)["container_port"] : 8080
  protocol    = lookup(element(var.load_balancer_config, count.index), "container_protocol", null) != null ? element(var.load_balancer_config, count.index)["container_protocol"] : "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path                = lookup(element(var.load_balancer_config, count.index), "container_check_health", null) != null ? element(var.load_balancer_config, count.index)["container_check_health"] : "/"
    protocol            = lookup(element(var.load_balancer_config, count.index), "container_protocol", null) != null ? element(var.load_balancer_config, count.index)["container_protocol"] : "HTTP"
    matcher             = lookup(element(var.load_balancer_config, count.index), "http_status_code", null) != null ? element(var.load_balancer_config, count.index)["http_status_code"] : "200"
    interval            = lookup(element(var.load_balancer_config, count.index), "interval", null) != null ? element(var.load_balancer_config, count.index)["interval"] : 15
    timeout             = lookup(element(var.load_balancer_config, count.index), "timeout", null) != null ? element(var.load_balancer_config, count.index)["timeout"] : 3
    healthy_threshold   = lookup(element(var.load_balancer_config, count.index), "healthy_threshold", null) != null ? element(var.load_balancer_config, count.index)["healthy_threshold"] : 2
    unhealthy_threshold = lookup(element(var.load_balancer_config, count.index), "unhealthy_threshold", null) != null ? element(var.load_balancer_config, count.index)["unhealthy_threshold"] : 2
  }
  stickiness {
    type            = lookup(element(var.load_balancer_config, count.index), "stickiness", null) != null ? element(var.load_balancer_config, count.index)["stickiness"]["type"] : "lb_cookie"
    enabled         = lookup(element(var.load_balancer_config, count.index), "stickiness", null) != null ? element(var.load_balancer_config, count.index)["stickiness"]["enabled"] : false
    cookie_duration = lookup(element(var.load_balancer_config, count.index), "stickiness", null) != null ? element(var.load_balancer_config, count.index)["stickiness"]["cookie_duration"] : null
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_lb.ecs_fargate_alb]
}

