## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## main.tf

```hcl
module "aws-leocinema" {
  source = "git::https://github.com/leonardobgsilva/module-tf-aws-leocinema-infra.git"

  aws_region       = var.aws_region
  vpc_config       = var.vpc_config
  instances_config = var.instances_config
  alb_config       = var.alb_config
  tags             = var.tags
}
```

## variables.tf

```hcl
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
```

## example.tfvars

```hcl
aws_region = "us-east-1"

vpc_config = {
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]
  public_subnets = {
    "pub-subnet-1" = { cidr = "10.0.1.0/24", az = "us-east-1a" },
    "pub-subnet-2" = { cidr = "10.0.2.0/24", az = "us-east-1b" }
  }
  private_subnets = {
    "priv-subnet-1" = { cidr = "10.0.3.0/24", az = "us-east-1a" },
    "priv-subnet-2" = { cidr = "10.0.4.0/24", az = "us-east-1b" }
  }
}

instances_config = {
  "red-app" = {
    instance_type  = "t3.micro",
    ami_id         = "ami-08a0d1e16fc3f61ea",
    port           = 80
    user_data_file = "user_data/red-app.sh"
    app_path       = "/red"
  },
  "green-app" = {
    instance_type  = "t3.micro",
    ami_id         = "ami-08a0d1e16fc3f61ea",
    port           = 80
    user_data_file = "user_data/green-app.sh"
    app_path       = "/green"
  }
}

alb_config = {
  name         = "lab-alb",
  enable_https = false
}

tags = {
  Project     = "Lab-AWS-Path-Routing",
  Environment = "Dev",
  Terraform   = "true"
}
```

## Resources

| Name | Type |
|------|------|
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_instance.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_config"></a> [alb\_config](#input\_alb\_config) | Configuration for Application Load Balancer | <pre>object({<br/>    name         = string<br/>    enable_https = bool<br/>  })</pre> | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region | `string` | n/a | yes |
| <a name="input_instances_config"></a> [instances\_config](#input\_instances\_config) | Configuration for EC2 instances | <pre>map(object({<br/>    instance_type  = string<br/>    ami_id         = string<br/>    port           = number<br/>    user_data_file = string<br/>    app_path       = string<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags for all resources | `map(string)` | n/a | yes |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | Configuration for VPC and subnets | <pre>object({<br/>    cidr_block      = string<br/>    azs             = list(string)<br/>    public_subnets  = map(object({ cidr = string, az = string }))<br/>    private_subnets = map(object({ cidr = string, az = string }))<br/>  })</pre> | n/a | yes |

