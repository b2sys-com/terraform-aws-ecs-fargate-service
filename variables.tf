variable "fargate_cluster_name" {
  description = "ECS Fargate Cluster name"
  type        = string
}

variable "cluster_id" {
  type        = string
  description = "Cluster id where you need to create services"
}

variable "container_name" {
  description = "(Required) The name of the container to expose to internet, associate with the load balancer (as it appears in a container definition)."
  type        = string
}

variable "fargate_services" {
  description = "Define fargate service information"
  default     = {}
}

variable "enable_execute_command" {
  description = "(Optional) Specifies whether to enable Amazon ECS Exec for the tasks within the service. Default: false"
  default     = false
  type        = bool
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security groups ids we need to add this cluster service"
  default     = []
}

variable "balancer_fargate_security_group_ids" {
  type        = list(string)
  description = "Fargate Security Group id. A list of security group IDs to assign to the LB. Only valid for Load Balancers of type application."
  default     = []
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The subnets associated with the task or service."
}

variable "load_balancer_config" {
  description = "Define Load Balancer Configuration for Fargate Services"
  default     = []
}

variable "balancer_allowed_subnet_ids" {
  type        = list(string)
  description = "The subnets allowed in the LB. (Optional) A list of subnet IDs to attach to the LB. Subnets cannot be updated for Load Balancers of type network. Changing this value for load balancers of type network will force a recreation of the resource."
}

variable "lb_idle_timeout" {
  type        = number
  description = "The time in seconds that the connection is allowed to be idle. Only valid for Load Balancers of type application. Default: 60."
  default     = 60
}

variable "vpc_id" {
  description = "Vpc id for this fargate cluster"
  type        = string
}

variable "assign_public_ip" {
  type        = bool
  description = "Assign a public IP address to the ENI (Fargate launch type only)."
  default     = false
}

variable "internal" {
  type        = bool
  description = "(Optional) If true, the LB will be internal."
  default     = false
}

variable "certificate_arn" {
  description = "Certificate ARN"
  type        = string
  default     = null
}

variable "access_logs" {
  type        = bool
  description = "(Optional) Boolean to enable / disable access_logs. Defaults to true"
  default     = true
}

variable "redirect_https" {
  type        = bool
  description = "Redirect HTTP to HTTPS"
  default     = false
}

variable "tags" {
  description = "Tags for fargate"
  type        = map(string)
}