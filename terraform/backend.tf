# ─────────────────────────────────────────────────────────────────────────────
# Remote State Backend — S3 + DynamoDB locking
# Uncomment and configure after creating the S3 bucket and DynamoDB table.
# ─────────────────────────────────────────────────────────────────────────────
#
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket-ap-south-1"
#     key            = "web-app-assignment/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }
#
# Bootstrap commands (run once before enabling backend):
#   aws s3api create-bucket \
#     --bucket your-terraform-state-bucket-ap-south-1 \
#     --region ap-south-1 \
#     --create-bucket-configuration LocationConstraint=ap-south-1
#
#   aws s3api put-bucket-versioning \
#     --bucket your-terraform-state-bucket-ap-south-1 \
#     --versioning-configuration Status=Enabled
#
#   aws dynamodb create-table \
#     --table-name terraform-state-lock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST \
#     --region ap-south-1
