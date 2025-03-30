variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_config" {
  type = object({
    cidr_block      = string
    azs             = list(string)
    public_subnets  = map(object({ cidr = string, az = string }))
    private_subnets = map(object({ cidr = string, az = string }))
  })
  description = "Configuration for VPC and subnets"
}

variable "instances_config" {
  type = map(object({
    instance_type  = string
    ami_id         = string
    port           = number
    user_data_file = string
    app_path       = string
  }))
  description = "Configuration for EC2 instances"
}

variable "alb_config" {
  type = object({
    name         = string
    enable_https = bool
  })
  description = "Configuration for Application Load Balancer"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}