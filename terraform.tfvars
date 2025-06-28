# terraform.tfvars - Development environment configuration
primary_region   = "us-east-1"
secondary_region = "us-west-2"
environment      = "dev"
project_name     = "disaster-recovery"

# Instance configuration
instance_type = "t2.micro"  # Free tier eligible

# Database configuration
db_username = "admin"
# db_password will be prompted or set via environment variable

# Monitoring
enable_monitoring = true
backup_retention_days = 7

# Security - IMPORTANT: Restrict this in production
allowed_cidr_blocks = ["0.0.0.0/0"]

# SSH Key - Update this path to your actual public key
public_key_path = "~/.ssh/id_rsa.pub"