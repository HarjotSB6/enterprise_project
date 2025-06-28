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

