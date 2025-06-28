# main.tf - AWS Disaster Recovery Infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Remote state configuration (use after initial setup)
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "disaster-recovery/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Primary region provider
provider "aws" {
  alias  = "primary"
  region = var.primary_region
  
  default_tags {
    tags = {
      Project     = "disaster-recovery-system"
      Environment = var.environment
      Owner       = "harjot-singh"
      CreatedBy   = "terraform"
      Region      = "primary"
    }
  }
}

# Secondary region provider for disaster recovery
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
  
  default_tags {
    tags = {
      Project     = "disaster-recovery-system"
      Environment = var.environment
      Owner       = "harjot-singh"
      CreatedBy   = "terraform"
      Region      = "secondary"
    }
  }
}

# Data sources
data "aws_ami" "amazon_linux_primary" {
  provider    = aws.primary
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "amazon_linux_secondary" {
  provider    = aws.secondary
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_availability_zones" "primary" {
  provider = aws.primary
  state    = "available"
}

data "aws_availability_zones" "secondary" {
  provider = aws.secondary
  state    = "available"
}

# VPC Configuration - Primary Region
resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "dr-primary-vpc"
  }
}

resource "aws_internet_gateway" "primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id
  
  tags = {
    Name = "dr-primary-igw"
  }
}

# Public subnets in primary region
resource "aws_subnet" "primary_public" {
  count                   = 2
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.primary.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "dr-primary-public-subnet-${count.index + 1}"
    Type = "public"
  }
}

# Private subnets in primary region
resource "aws_subnet" "primary_private" {
  count             = 2
  provider          = aws.primary
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.primary.names[count.index]
  
  tags = {
    Name = "dr-primary-private-subnet-${count.index + 1}"
    Type = "private"
  }
}

# Route table for public subnets - Primary
resource "aws_route_table" "primary_public" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary.id
  }
  
  tags = {
    Name = "dr-primary-public-rt"
  }
}

resource "aws_route_table_association" "primary_public" {
  count          = 2
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_public[count.index].id
  route_table_id = aws_route_table.primary_public.id
}

# NAT Gateway for private subnets
resource "aws_eip" "primary_nat" {
  provider = aws.primary
  domain   = "vpc"
  
  tags = {
    Name = "dr-primary-nat-eip"
  }
}

resource "aws_nat_gateway" "primary" {
  provider      = aws.primary
  allocation_id = aws_eip.primary_nat.id
  subnet_id     = aws_subnet.primary_public[0].id
  
  tags = {
    Name = "dr-primary-nat"
  }
  
  depends_on = [aws_internet_gateway.primary]
}

# Route table for private subnets - Primary
resource "aws_route_table" "primary_private" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.primary.id
  }
  
  tags = {
    Name = "dr-primary-private-rt"
  }
}

resource "aws_route_table_association" "primary_private" {
  count          = 2
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_private[count.index].id
  route_table_id = aws_route_table.primary_private.id
}

# VPC Configuration - Secondary Region
resource "aws_vpc" "secondary" {
  provider             = aws.secondary
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "dr-secondary-vpc"
  }
}

resource "aws_internet_gateway" "secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id
  
  tags = {
    Name = "dr-secondary-igw"
  }
}

# Public subnets in secondary region
resource "aws_subnet" "secondary_public" {
  count                   = 2
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = "10.1.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.secondary.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "dr-secondary-public-subnet-${count.index + 1}"
    Type = "public"
  }
}

# Private subnets in secondary region
resource "aws_subnet" "secondary_private" {
  count             = 2
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = "10.1.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.secondary.names[count.index]
  
  tags = {
    Name = "dr-secondary-private-subnet-${count.index + 1}"
    Type = "private"
  }
}

# Route table for public subnets - Secondary
resource "aws_route_table" "secondary_public" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary.id
  }
  
  tags = {
    Name = "dr-secondary-public-rt"
  }
}

resource "aws_route_table_association" "secondary_public" {
  count          = 2
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_public[count.index].id
  route_table_id = aws_route_table.secondary_public.id
}

# Security Groups
resource "aws_security_group" "web_primary" {
  provider    = aws.primary
  name_prefix = "dr-web-primary-"
  vpc_id      = aws_vpc.primary.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "dr-web-primary-sg"
  }
}

resource "aws_security_group" "web_secondary" {
  provider    = aws.secondary
  name_prefix = "dr-web-secondary-"
  vpc_id      = aws_vpc.secondary.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "dr-web-secondary-sg"
  }
}

# Key Pairs
resource "aws_key_pair" "primary" {
  provider   = aws.primary
  key_name   = "dr-key-primary"
  public_key = file(var.public_key_path)
  
  tags = {
    Name = "dr-primary-keypair"
  }
}

resource "aws_key_pair" "secondary" {
  provider   = aws.secondary
  key_name   = "dr-key-secondary"
  public_key = file(var.public_key_path)
  
  tags = {
    Name = "dr-secondary-keypair"
  }
}

# Application Load Balancer - Primary
resource "aws_lb" "primary" {
  provider           = aws.primary
  name               = "dr-primary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_primary.id]
  subnets           = aws_subnet.primary_public[*].id
  
  enable_deletion_protection = false
  
  tags = {
    Name = "dr-primary-alb"
  }
}

resource "aws_lb_target_group" "primary" {
  provider = aws.primary
  name     = "dr-primary-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.primary.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  tags = {
    Name = "dr-primary-tg"
  }
}

resource "aws_lb_listener" "primary" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.primary.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary.arn
  }
}

# EC2 Instances - Primary Region
resource "aws_instance" "primary_web_servers" {
  count                  = 2
  provider               = aws.primary
  ami                    = data.aws_ami.amazon_linux_primary.id
  instance_type          = "t2.micro"  # Free tier eligible
  key_name               = aws_key_pair.primary.key_name
  vpc_security_group_ids = [aws_security_group.web_primary.id]
  subnet_id              = aws_subnet.primary_public[count.index].id
  
  user_data = base64encode(templatefile("${path.module}/scripts/install_app.sh", {
    region = var.primary_region
    server_id = count.index + 1
  }))
  
  tags = {
    Name = "dr-primary-web-${count.index + 1}"
    Role = "web-server"
    Tier = "primary"
  }
}

# Attach instances to target group
resource "aws_lb_target_group_attachment" "primary" {
  count            = 2
  provider         = aws.primary
  target_group_arn = aws_lb_target_group.primary.arn
  target_id        = aws_instance.primary_web_servers[count.index].id
  port             = 80
}

# RDS Subnet Group - Primary
resource "aws_db_subnet_group" "primary" {
  provider   = aws.primary
  name       = "dr-primary-db-subnet-group"
  subnet_ids = aws_subnet.primary_private[*].id
  
  tags = {
    Name = "dr-primary-db-subnet-group"
  }
}

# RDS Instance - Primary
resource "aws_db_instance" "primary" {
  provider                = aws.primary
  identifier              = "dr-primary-db"
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"  # Free tier eligible
  db_name                 = "disaster_recovery"
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = "default.mysql8.0"
  db_subnet_group_name    = aws_db_subnet_group.primary.name
  vpc_security_group_ids  = [aws_security_group.db_primary.id]
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  skip_final_snapshot    = true
  
  # Enable automated backups and cross-region replication
  copy_tags_to_snapshot = true
  
  tags = {
    Name = "dr-primary-database"
  }
}

# Security Group for RDS - Primary
resource "aws_security_group" "db_primary" {
  provider    = aws.primary
  name_prefix = "dr-db-primary-"
  vpc_id      = aws_vpc.primary.id
  
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_primary.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "dr-db-primary-sg"
  }
}

# S3 Bucket for application data and backups
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "${var.project_name}-primary-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "dr-primary-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Cross-region replication bucket
resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket   = "${var.project_name}-secondary-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "dr-secondary-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Cross-Region Replication
resource "aws_s3_bucket_replication_configuration" "primary_to_secondary" {
  provider   = aws.primary
  role       = aws_iam_role.replication.arn
  bucket     = aws_s3_bucket.primary.id
  depends_on = [aws_s3_bucket_versioning.primary]
  
  rule {
    id     = "replicate-to-secondary"
    status = "Enabled"
    
    destination {
      bucket        = aws_s3_bucket.secondary.arn
      storage_class = "STANDARD_IA"
    }
  }
}

# IAM Role for S3 replication
resource "aws_iam_role" "replication" {
  provider = aws.primary
  name     = "dr-s3-replication-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "replication" {
  provider = aws.primary
  name     = "dr-s3-replication-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "${aws_s3_bucket.primary.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.primary.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = "${aws_s3_bucket.secondary.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  provider   = aws.primary
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# Random string for unique resource naming
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}