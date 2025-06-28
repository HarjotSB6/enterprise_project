# outputs.tf - Output values
output "primary_vpc_id" {
  description = "ID of the primary VPC"
  value       = aws_vpc.primary.id
}

output "secondary_vpc_id" {
  description = "ID of the secondary VPC"
  value       = aws_vpc.secondary.id
}

output "primary_load_balancer_dns" {
  description = "DNS name of the primary load balancer"
  value       = aws_lb.primary.dns_name
}

output "primary_load_balancer_url" {
  description = "URL of the primary load balancer"
  value       = "http://${aws_lb.primary.dns_name}"
}

output "primary_web_server_ips" {
  description = "Public IP addresses of primary web servers"
  value       = aws_instance.primary_web_servers[*].public_ip
}

output "primary_database_endpoint" {
  description = "RDS instance endpoint in primary region"
  value       = aws_db_instance.primary.endpoint
  sensitive   = true
}

output "s3_primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.primary.bucket
}

output "s3_secondary_bucket_name" {
  description = "Name of the secondary S3 bucket"
  value       = aws_s3_bucket.secondary.bucket
}

output "ssh_connection_commands" {
  description = "SSH commands to connect to the instances"
  value = {
    for i, instance in aws_instance.primary_web_servers :
    "primary-web-${i + 1}" => "ssh -i ~/.ssh/id_rsa ec2-user@${instance.public_ip}"
  }
}

output "application_urls" {
  description = "URLs to access the applications"
  value = {
    primary_load_balancer = "http://${aws_lb.primary.dns_name}"
    primary_servers = [
      for instance in aws_instance.primary_web_servers :
      "http://${instance.public_ip}"
    ]
  }
}

output "resource_summary" {
  description = "Summary of created resources"
  value = {
    primary_region = var.primary_region
    secondary_region = var.secondary_region
    vpc_primary = aws_vpc.primary.id
    vpc_secondary = aws_vpc.secondary.id
    instances_created = length(aws_instance.primary_web_servers)
    database_created = aws_db_instance.primary.identifier
    load_balancer_created = aws_lb.primary.name
    s3_buckets_created = [aws_s3_bucket.primary.bucket, aws_s3_bucket.secondary.bucket]
  }
}