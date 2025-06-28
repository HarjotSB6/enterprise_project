provider "aws" {
  region = var.aws_region
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
