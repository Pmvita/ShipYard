variable "aws_region" {
  description = "AWS region for the destroyable lab stack."
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Name prefix for resources."
  type        = string
  default     = "shipyard"
}

variable "image_tag" {
  description = "Immutable container image tag (git SHA). Used by CI on every main push."
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "App listen port inside the task."
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "ECS service desired task count. Keep at 1 for the lab."
  type        = number
  default     = 1
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory (MiB)."
  type        = number
  default     = 512
}

variable "alert_email" {
  description = "Email for SNS alarm subscription and budget alerts. Empty skips SNS subscription confirm step."
  type        = string
  default     = ""
}

variable "budget_limit_usd" {
  description = "Monthly AWS Budget limit (USD) for this account scope."
  type        = string
  default     = "1"
}

variable "github_org" {
  description = "GitHub org or user that owns the ShipYard repo (OIDC trust)."
  type        = string
  default     = "Pmvita"
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust."
  type        = string
  default     = "ShipYard"
}

variable "ecr_keep_images" {
  description = "ECR lifecycle: keep last N images."
  type        = number
  default     = 10
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false if the account already has token.actions.githubusercontent.com."
  type        = bool
  default     = true
}
