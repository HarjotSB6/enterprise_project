provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "${var.app_name}-upload-bucket"
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
  source        = "../../modules/backend"
  providers = {
    aws = aws.use1
  }
  app_name      = var.app_name
  db_name       = "appdb"
  db_username   = "admin"
  db_password   = "AppPass123!"  # Store this in Secrets Manager in production
  subnet_ids    = module.vpc.public_subnet_ids
  db_sg_id      = module.vpc.default_sg_id
}
