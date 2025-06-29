output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "default_sg_id" {
  value = aws_vpc.main.default_security_group_id
}
