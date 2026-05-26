output "app_launch_template_id" {
  value = aws_launch_template.app.id
}


output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}
