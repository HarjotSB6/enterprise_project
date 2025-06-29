provider "aws" {
  region = "us-east-1"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_bucket" {
  bucket        = "${var.app_name}-upload-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

module "vpc" {
  source = "../../modules/vpc"

  env_name            = var.env_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "eks" {
  source           = "../../modules/eks"
  aws_region       = var.aws_region
  cluster_name     = "${var.env_name}-eks-cluster"
  subnet_ids       = module.vpc.public_subnet_ids

  node_desired_size   = 1
  node_max_size       = 1
  node_min_size       = 1
  node_instance_types = ["t2.micro"]
}

module "backend" {
  source      = "../../modules/backend"
  app_name    = var.app_name
  db_name     = "appdb"
  db_username = "appadmin"
  db_password = "AppPass123!"
  subnet_ids  = module.vpc.public_subnet_ids
  db_sg_id    = module.vpc.default_sg_id
}

# SNS Topic created here in root module
resource "aws_sns_topic" "notify" {
  name = "${var.app_name}-s3-notify-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notify.arn
  protocol  = "email"
  endpoint  = "harjotsb56@gmail.com"
}

module "s3_notification" {
  source           = "../../modules/s3_notification"
  app_name         = var.app_name
  s3_bucket_id     = aws_s3_bucket.app_bucket.id
  sns_topic_arn    = aws_sns_topic.notify.arn
  lambda_exec_role = module.backend.lambda_exec_role_arn
  email_address    = "harjotsb56@gmail.com"
}
