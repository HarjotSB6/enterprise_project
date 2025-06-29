variable "app_name" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}

variable "subnet_ids" {
  type = list(string)
}

variable "db_sg_id" {
  description = "Security Group ID to attach to DB"
}
