provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_config.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "lab-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "lab-igw" })
}

resource "aws_subnet" "public" {
  for_each = var.vpc_config.public_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = merge(var.tags, { Name = each.key })
}

resource "aws_subnet" "private" {
  for_each = var.vpc_config.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = merge(var.tags, { Name = each.key })
}

resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "${each.key}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags          = merge(var.tags, { Name = "${each.key}-nat-gw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, { Name = "public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = toset(var.vpc_config.azs)

  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this["pub-subnet-${index(var.vpc_config.azs, each.value) + 1}"].id
  }
  tags = merge(var.tags, { Name = "private-rt-${each.value}" })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.value.availability_zone].id
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.alb_config.enable_https ? [80, 443] : [80]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "alb-sg" })
}

resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.this.id

  dynamic "ingress" {
    for_each = [for app in var.instances_config : app.port]
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.alb.id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "ec2-sg" })
}

resource "aws_instance" "app" {
  for_each = var.instances_config

  ami                    = each.value.ami_id
  instance_type          = each.value.instance_type
  subnet_id              = aws_subnet.private[keys(var.vpc_config.private_subnets)[0]].id # Alterna entre subnets
  vpc_security_group_ids = [aws_security_group.ec2.id]
  user_data              = file("${path.module}/../../${each.value.user_data_file}")

  tags = merge(var.tags, {
    Name = each.key
    App  = split("-", each.key)[0]
  })
}

resource "aws_lb" "this" {
  name               = var.alb_config.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  tags = merge(var.tags, { Name = var.alb_config.name })
}

resource "aws_lb_target_group" "app" {
  for_each = var.instances_config

  name     = "tg-${each.key}"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, { Name = "tg-${each.key}" })
}

resource "aws_lb_target_group_attachment" "app" {
  for_each = aws_instance.app

  target_group_arn = aws_lb_target_group.app[each.key].arn
  target_id        = each.value.id
  port             = var.instances_config[each.key].port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "app" {
  for_each = var.instances_config

  listener_arn = aws_lb_listener.http.arn
  priority     = index(keys(var.instances_config), each.key) + 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[each.key].arn
  }

  condition {
    path_pattern {
      values = [
        "${each.value.app_path}",  # Cobre exatamente /red ou /green
        "${each.value.app_path}/", # Cobre /red/ ou /green/
        "${each.value.app_path}/*" # Cobre /red/qualquer-coisa ou /green/qualquer-coisa
      ]
    }
  }
}