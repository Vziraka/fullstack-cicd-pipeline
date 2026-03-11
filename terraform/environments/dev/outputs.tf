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
