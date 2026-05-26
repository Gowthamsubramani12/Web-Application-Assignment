variable "vpc_id" { type = string }
variable "public_subnets" { type = list(string) }
variable "app_security_group" { type = string }
variable "instance_type" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
variable "key_name" {
  type    = string
  default = ""
}
variable "image_tag" { type = string }
