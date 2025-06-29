output "db_endpoint" {
  value = aws_db_instance.app_db.endpoint
}

output "bucket_name" {
  value = aws_s3_bucket.app_bucket.id
}

output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}
