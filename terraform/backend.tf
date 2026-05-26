# ─────────────────────────────────────────────────────────────────────────────
# Remote State Backend — S3 + DynamoDB locking
# Uncomment and configure after creating the S3 bucket and DynamoDB table.
# ─────────────────────────────────────────────────────────────────────────────
#
terraform {
  backend "s3" {
    bucket       = "webapp-backend-assesment"
    key          = "web-app-assignment/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}
