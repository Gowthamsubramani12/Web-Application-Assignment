output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}



output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ec2.ecr_repository_url
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}
