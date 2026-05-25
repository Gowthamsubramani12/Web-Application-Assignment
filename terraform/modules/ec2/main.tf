data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-repo-${var.environment}"
  image_tag_mutability = "MUTABLE"

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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
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
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              
              # AWS CLI is pre-installed on AL2023. Login to ECR:
              aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}
              
              # Run the application container (Nginx on port 80)
              docker run -d -p 80:80 --name app ${aws_ecr_repository.app.repository_url}:latest || true
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Jenkins EC2 Instance in Public Subnet
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnets[0]
  vpc_security_group_ids      = [var.jenkins_sg_id]
  associate_public_ip_address = true

  # IAM role with ECR push/pull permissions would be attached here in a real scenario
  # but keeping it simple as requested

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git
              systemctl start docker
              systemctl enable docker
              
              # Run Jenkins in Docker
              mkdir -p /var/jenkins_home
              chown -R 1000:1000 /var/jenkins_home
              docker run -d -p 8080:8080 -p 50000:50000 \
                -v /var/jenkins_home:/var/jenkins_home \
                -v /var/run/docker.sock:/var/run/docker.sock \
                --name jenkins jenkins/jenkins:lts
              EOF

  tags = {
    Name = "${var.project_name}-jenkins-${var.environment}"
  }
}
