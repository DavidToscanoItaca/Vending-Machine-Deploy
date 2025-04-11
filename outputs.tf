output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.vm_alb.dns_name
}

output "bastion_public_ip" {
  description = "Public Elastic IP address of the Bastion host"
  value       = aws_eip.bastion_eip.public_ip
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.vm_repo.repository_url
}
