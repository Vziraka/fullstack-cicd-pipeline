output "ecr_repository_url" {
  description = "The URL used to push and pull Docker images. Use this in your docker push command."
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the ECR repository."
  value       = aws_ecr_repository.app.arn
}

output "ecr_push_pull_role_arn" {
  description = "The ARN of the IAM role for GitHub Actions to push/pull images. Add this to GitHub Secrets as ECR_ROLE_ARN."
  value       = aws_iam_role.ecr_push_pull.arn
}

output "aws_account_id" {
  description = "Your AWS account ID. Used in docker login command."
  value       = data.aws_caller_identity.current.account_id
}

output "alb_dns_name" {
  description = "The public URL of the load balancer. Hit this to reach your API."
  value       = "http://${aws_lb.app.dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name. Used in GitHub Actions deploy step."
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "ECS service name. Used in GitHub Actions deploy step."
  value       = aws_ecs_service.app.name
}

output "ecs_task_family" {
  description = "Task definition family name. Used in GitHub Actions to render new task definition."
  value       = aws_ecs_task_definition.app.family
}

output "alb_prod_url" {
  description = "Production URL — port 8080 on the shared ALB."
  value       = "http://${aws_lb.app.dns_name}:8080"
}

output "ecs_prod_service_name" {
  description = "Production ECS service name."
  value       = aws_ecs_service.app_prod.name
}

output "ecs_prod_task_family" {
  description = "Production task definition family name."
  value       = aws_ecs_task_definition.app_prod.family
}
