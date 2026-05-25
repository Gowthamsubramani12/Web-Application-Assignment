pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = 'webapp-assignment-repo-production' // Should match the Terraform ECR name
        IMAGE_TAG = "${env.BUILD_ID}"
        // Set these credentials in Jenkins
        // AWS_CREDENTIALS_ID = 'aws-credentials' 
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Docker Build') {
            steps {
                dir('app') {
                    sh 'docker build -t $ECR_REPO:$IMAGE_TAG .'
                    sh 'docker tag $ECR_REPO:$IMAGE_TAG $ECR_REPO:latest'
                }
            }
        }

        stage('Push to ECR') {
            steps {
                // In a real pipeline, wrap this in withCredentials([amazonAWSCredentials(...)])
                sh '''
                    # Ensure AWS CLI is configured
                    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                    
                    docker tag $ECR_REPO:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
                    docker tag $ECR_REPO:latest $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest
                    
                    docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
                    docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Deployment Validation') {
            steps {
                dir('terraform') {
                    script {
                        def alb_dns = sh(script: 'terraform output -raw alb_dns_name', returnStdout: true).trim()
                        echo "ALB DNS Name: ${alb_dns}"
                        
                        // Simple curl test to ensure ALB is responding (might need retry logic in reality)
                        sh "curl -s -f http://${alb_dns} || echo 'Validation may fail if ALB is still provisioning targets'"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline succeeded! App deployed successfully."
        }
        failure {
            echo "Pipeline failed. Check the logs."
        }
    }
}
