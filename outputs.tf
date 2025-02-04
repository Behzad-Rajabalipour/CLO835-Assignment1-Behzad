output "worker_node_public_ip" {
  description = "Public IP of the worker node"
  value       = aws_instance.worker_node.public_ip
}

output "ecr_user_access_key_id" {
  description = "IAM user access key ID"
  value       = aws_iam_access_key.ecr_user_key.id
}

output "ecr_user_secret_access_key" {
  description = "IAM user secret access key"
  value       = aws_iam_access_key.ecr_user_key.secret
  sensitive   = true
}
