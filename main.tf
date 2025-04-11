terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.94.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  num_azs = 2
  tags = {
    Project     = "vm-app"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

#--------------------------------------
# Networking
#--------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.19.0"

  name            = "vm-vpc"
  cidr            = var.vpc_cidr
  azs             = slice(data.aws_availability_zones.available.names, 0, local.num_azs)
  public_subnets  = [for k, v in slice(data.aws_availability_zones.available.names, 0, local.num_azs) : var.public_subnet_cidrs[k]]
  private_subnets = [for k, v in slice(data.aws_availability_zones.available.names, 0, local.num_azs) : var.private_subnet_cidrs[k]]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags  = merge(local.tags, { Name = "vm-public-subnet" })
  private_subnet_tags = merge(local.tags, { Name = "vm-private-subnet" })
  vpc_tags            = local.tags
}

# Data source to inspect the first private route table
data "aws_route_table" "private" {
  # Assumes single_nat_gateway = true, so only one private route table is relevant
  route_table_id = module.vpc.private_route_table_ids[0]
}

#--------------------------------------
# Security Groups
#--------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "vm-alb-sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = merge(local.tags, { Name = "vm-alb-sg" })
}

resource "aws_security_group" "fargate_sg" {
  name        = "vm-fargate-sg"
  description = "Allow traffic from ALB to Fargate container"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow traffic from ALB"
  }
  # Allow traffic from bastion SG for direct testing
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "Allow direct container access from Bastion (for testing)"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic (for ECR pull, etc.)"
  }
  tags = merge(local.tags, { Name = "vm-fargate-sg" })
}

resource "aws_security_group" "bastion_sg" {
  name        = "vm-bastion-sg"
  description = "Allow SSH from specific IPs to Bastion"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidr
    description = "Allow SSH from trusted IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = merge(local.tags, { Name = "vm-bastion-sg" })
}

#--------------------------------------
# ECR Repository
#--------------------------------------
resource "aws_ecr_repository" "vm_repo" {
  name                 = "vm"
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # delete repo on destroy

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.tags, { Name = "vm-ecr-repo" })
}

resource "null_resource" "docker_build_push" {

  depends_on = [aws_ecr_repository.vm_repo]

  provisioner "local-exec" {
    working_dir = path.module
    command     = <<-EOT
      # Login
      $ecrPasswordBuild = aws ecr get-login-password --region ${var.aws_region};
      docker login --username AWS --password $ecrPasswordBuild ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com;
      # Build the image
      docker build -t ${aws_ecr_repository.vm_repo.repository_url}:latest .;
      # Push the image
      docker push ${aws_ecr_repository.vm_repo.repository_url}:latest;
    EOT
    interpreter = ["powershell", "-Command"]
    #interpreter = ["bash", "-c"]

  }
}

#--------------------------------------
# IAM Roles & Policies
#--------------------------------------

# Role for Fargate tasks to pull images, write logs
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "vm-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
  tags = merge(local.tags, { Name = "vm-ecs-task-execution-role" })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


#--------------------------------------
# ECS Cluster
#--------------------------------------
resource "aws_ecs_cluster" "vm_cluster" {
  name = "vm-cluster"
  tags = merge(local.tags, { Name = "vm-cluster" })

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

#--------------------------------------
# ECS Task Definition
#--------------------------------------
resource "aws_ecs_task_definition" "vm_task_def" {
  family                   = "vm-task-def"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  tags                     = merge(local.tags, { Name = "vm-task-def" })

  container_definitions = jsonencode([{
    name      = "vm-container"
    image     = "${aws_ecr_repository.vm_repo.repository_url}:latest"
    cpu       = var.container_cpu
    memory    = var.container_memory
    essential = true
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/vm-app" # CloudWatch Log Group name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# CloudWatch Log Group for the container
resource "aws_cloudwatch_log_group" "vm_log_group" {
  name              = "/ecs/vm-app"
  retention_in_days = 7
  tags              = merge(local.tags, { Name = "vm-log-group" })
}

#--------------------------------------
# Application Load Balancer (ALB)
#--------------------------------------
resource "aws_lb" "vm_alb" {
  name               = "vm-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
  tags                       = merge(local.tags, { Name = "vm-alb" })
}

resource "aws_lb_target_group" "vm_tg" {
  name        = "vm-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip" # Required for Fargate

  health_check {
    enabled             = true
    interval            = 30
    path                = "/beverages"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = merge(local.tags, { Name = "vm-tg" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.vm_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action: Return 404 Not Found if no rules match
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
  tags = merge(local.tags, { Name = "vm-alb-listener-http" })
}

# Rule for Private /ingredients API
resource "aws_lb_listener_rule" "ingredients_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vm_tg.arn
  }

  condition {
    path_pattern {
      values = ["/ingredients*"]
    }
  }
  condition {
    source_ip {
      values = concat(var.private_api_allowed_cidr, ["${aws_eip.bastion_eip.public_ip}/32"]) # bastion host EIP, it allows requests on fargate app
    }
  }
}

# Rule for Public /beverages API
resource "aws_lb_listener_rule" "beverages_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vm_tg.arn
  }

  condition {
    path_pattern {
      values = ["/beverages*"]
    }
  }
  # No source_ip -> from anywhere
}

#--------------------------------------
# ECS Service
#--------------------------------------
resource "aws_ecs_service" "vm_service" {
  name                    = "vm-service"
  cluster                 = aws_ecs_cluster.vm_cluster.id
  task_definition         = aws_ecs_task_definition.vm_task_def.arn
  desired_count           = 1
  launch_type             = "FARGATE"
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"
  depends_on = [
    aws_lb_listener_rule.ingredients_rule,
    aws_lb_listener_rule.beverages_rule
  ]

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.fargate_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.vm_tg.arn
    container_name   = "vm-container"
    container_port   = var.container_port
  }

  tags = merge(local.tags, { Name = "vm-service" })
}

#--------------------------------------
# Bastion Host
#--------------------------------------
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.bastion_instance_type
  subnet_id              = module.vpc.public_subnets[0] # first public subnet
  key_name               = var.bastion_ssh_key_name     # IMPORTANT: Key must exist
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = merge(local.tags, { Name = "vm-bastion" })
}

resource "aws_eip" "bastion_eip" {
  domain     = "vpc"
  depends_on = [module.vpc.aws_internet_gateway] # IGW must exists before EIP
  tags       = merge(local.tags, { Name = "vm-bastion-eip" })
}

resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}
