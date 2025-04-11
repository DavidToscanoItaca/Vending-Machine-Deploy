variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "private_api_allowed_cidr" {
  description = "List of CIDR blocks allowed to access the /ingredients API via the ALB"
  type        = list(string)
}

variable "bastion_allowed_cidr" {
  description = "CIDR block allowed SSH access to the Bastion host"
  type        = list(string)
  # IMPORTANT: Replace with your public IP address /32
  default = ["0.0.0.0/0"] # CHANGE THIS
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the Bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_ssh_key_name" {
  description = "Name of an existing EC2 Key Pair to use for the bastion host"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "container_cpu" {
  description = "CPU units for the Fargate task"
  type        = number
  default     = 256 # 0.25 vCPU
}

variable "container_memory" {
  description = "Memory (in MiB) for the Fargate task"
  type        = number
  default     = 512 # 0.5 GB
}
