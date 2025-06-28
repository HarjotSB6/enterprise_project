variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the EKS cluster"
}

variable "node_desired_size" {
  type        = number
  default     = 2
}

variable "node_max_size" {
  type        = number
  default     = 3
}

variable "node_min_size" {
  type        = number
  default     = 1
}

variable "node_instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
}
