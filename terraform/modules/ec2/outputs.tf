output "app_launch_template_id" {
  value = aws_launch_template.app.id
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}
