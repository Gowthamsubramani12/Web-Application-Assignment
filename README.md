# AWS Production Architecture for Containerized Web App

## 🏗️ Architecture Overview

This project provisions a highly available, production-like AWS architecture using **Terraform** to host a containerized Nginx web application. It includes a CI/CD pipeline defined with a **Jenkinsfile** that automates the Docker image build, push to ECR, and infrastructure update.

**Region**: `ap-south-1` (Mumbai)

### Flow
`Users -> Internet Gateway -> ALB (Public Subnet) -> ASG (Private Subnet) -> EC2 instances running Docker (Nginx App)`

## 🎯 Design Decisions

1. **Network Segregation**: Two public subnets for the Application Load Balancer and Jenkins CI server. Two private subnets for the application EC2 instances to improve security. A NAT gateway in the public subnet allows private instances to fetch Docker images from ECR.
2. **Compute Layer**: Used an Auto Scaling Group (ASG) coupled with an EC2 Launch Template. Instances pull the latest Docker image from ECR upon boot using `user_data`.
3. **Application Stack**: Shifted to a lightweight Nginx image instead of Flask for faster startup, minimal resource consumption, and better performance for static content.
4. **CI/CD Integration**: A standalone Jenkins EC2 instance runs Jenkins inside a Docker container. The Jenkins pipeline is fully integrated with Terraform to perform Infrastructure as Code (IaC) continuous deployment.

## 🚀 Deployment Workflow

1. **Commit Code**: A developer pushes code to GitHub.
2. **Jenkins Pipeline Triggered**:
   - Checkout SCM.
   - Build Nginx Docker image.
   - Push image to AWS ECR.
   - Run `terraform init`, `plan`, and `apply` to ensure the ASG launch template reflects any changes or just verifies infra state.
   - Post-deployment Validation: Test the ALB endpoint.

## 🔐 Security Considerations

- **Least Privilege Security Groups**:
  - **ALB**: Open to `80/443` from `0.0.0.0/0`.
  - **App Instances**: Open to port `80` *only* from the ALB Security Group. No direct internet access.
  - **Jenkins**: Open to `8080` and `22` *only* from a specific IP (configured via `terraform.tfvars`).
- **IAM Roles**: App EC2 instances use an Instance Profile with an IAM Role that only has permissions to pull from ECR and send logs to CloudWatch.

## ⚖️ Trade-offs Considered

- **Managed Services vs Custom Compute**: We used EC2 instances running Docker instead of ECS/EKS. While ECS/Fargate reduces maintenance overhead, using raw EC2 with an ASG demonstrates foundational AWS compute and networking skills.
- **Single Jenkins Server**: To save costs and simplify, Jenkins is a single EC2 instance. In a true enterprise setup, a Jenkins master-worker architecture or AWS CodePipeline would provide higher availability.

## 💰 Cost Optimization Strategy

- Used `t3.micro` instances for both Jenkins and the app instances (eligible for free tier in some accounts, generally low cost).
- ASG minimum size kept at `1` and desired at `2` to balance high availability with cost.
- Single NAT Gateway instead of one per AZ (saves ~$32/month, though slightly reduces high availability for outbound traffic).
- ECR Lifecycle Policy configured to automatically delete old images, keeping only the last 5.

## 📊 Monitoring Setup

- **CloudWatch Alarms**: Configured for High/Low CPU utilization on the ASG and high Target Response Time on the ALB.
- **CloudWatch Logs**: Application EC2 instances are configured with the SSM agent, ready to stream logs.

## 🔮 Future Improvements

1. **HTTPS / TLS**: Add Route53 DNS and AWS Certificate Manager (ACM) to the ALB for end-to-end encryption.
2. **Managed Container Orchestration**: Migrate the workload to AWS ECS Fargate for reduced EC2 management.
3. **Remote Backend**: The `backend.tf` is currently commented out. Enabling S3 + DynamoDB state locking is essential for team collaboration.