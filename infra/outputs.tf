output "alb_dns_name" {
  description = "Public ALB DNS name. Hit http://<this>/health after apply."
  value       = aws_lb.app.dns_name
}

output "alb_url" {
  description = "Convenience HTTP URL for the service."
  value       = "http://${aws_lb.app.dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL for docker push."
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "github_actions_role_arn" {
  description = "Set as GitHub Actions secret AWS_ROLE_ARN for OIDC deploy."
  value       = aws_iam_role.github_actions.arn
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.app.name
}

output "image_uri_example" {
  description = "Example image URI using the current image_tag variable."
  value       = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
}
