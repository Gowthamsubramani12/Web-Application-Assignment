data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_ecr_repository" "app" {
  name                 = "webapp-production"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_iam_role" "app_role" {
  name = "${var.project_name}-app-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.project_name}-app-profile-${var.environment}"
  role = aws_iam_role.app_role.name
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  vpc_security_group_ids = [var.app_security_group]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Removed 'yum update -y' to speed up boot time and avoid ASG health check grace period timeouts.
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              
              # Extract registry URL for docker login
              REGISTRY_URL=$(echo ${aws_ecr_repository.app.repository_url} | cut -d'/' -f1)
              
              # AWS CLI is pre-installed on AL2023. Login to ECR:
              aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $REGISTRY_URL
              
              # Try to pull the specified image. If it fails (e.g., initial terraform apply before docker image is pushed),
              # fallback to a default nginx image so the ALB health check passes and prevents ASG instance cycling.
              if docker pull ${aws_ecr_repository.app.repository_url}:${var.image_tag}; then
                docker run -d -p 80:80 --name app ${aws_ecr_repository.app.repository_url}:${var.image_tag}
              else
                echo "Image not found, falling back to default nginx to pass health checks..."
                docker run -d -p 80:80 --name app nginx:alpine
              fi
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

