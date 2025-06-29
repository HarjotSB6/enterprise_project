resource "aws_db_instance" "app_db" {
  identifier         = "${var.app_name}-db"
  allocated_storage  = 20
  engine             = "postgres"
  engine_version     = "15.13"
  instance_class     = "db.t3.micro" 
  username           = var.db_username
  password           = var.db_password
  db_name            = var.db_name
  publicly_accessible = true
  skip_final_snapshot = true

  vpc_security_group_ids = [var.db_sg_id]
  db_subnet_group_name = aws_db_subnet_group.default.name
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.app_name}-db-subnet-group"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_bucket" {
  bucket        = "${var.app_name}-upload-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true
}


resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.app_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_basic_exec" {
  name       = "${var.app_name}-lambda-policy-attach"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
