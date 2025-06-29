variable "app_name" {
  description = "App name prefix"
  type        = string
}

variable "s3_bucket_id" {
  description = "ID of the S3 bucket to monitor"
  type        = string
}

variable "email_address" {
  description = "Email to receive notifications"
  type        = string
}
