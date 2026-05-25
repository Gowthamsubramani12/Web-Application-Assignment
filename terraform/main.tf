module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  project_name         = var.project_name
  environment          = var.environment
}

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  environment  = var.environment
  your_ip      = var.your_ip
}

module "alb" {
  source = "./modules/alb"

  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnet_ids
  security_groups = [module.security_groups.alb_sg_id]
  project_name    = var.project_name
  environment     = var.environment
}

module "ec2" {
  source = "./modules/ec2"

  vpc_id              = module.vpc.vpc_id
  public_subnets      = module.vpc.public_subnet_ids
  app_security_group  = module.security_groups.app_sg_id
  jenkins_sg_id       = module.security_groups.jenkins_sg_id
  instance_type       = var.instance_type
  key_name            = var.key_name
  project_name        = var.project_name
  environment         = var.environment
}

module "autoscaling" {
  source = "./modules/autoscaling"

  vpc_zone_identifier = module.vpc.private_subnet_ids
  launch_template_id  = module.ec2.app_launch_template_id
  target_group_arn    = module.alb.target_group_arn
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  project_name        = var.project_name
  environment         = var.environment
}

module "monitoring" {
  source = "./modules/monitoring"

  alb_arn_suffix        = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  asg_name              = module.autoscaling.asg_name
  project_name          = var.project_name
  environment           = var.environment
}
