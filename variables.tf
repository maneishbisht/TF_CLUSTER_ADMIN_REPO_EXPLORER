variable "aws_region" {
  description = "AWS region containing the EKS clusters."
  type        = string
  default     = "ap-south-1"
}

variable "argocd_chart_version" {
  description = "Pinned Argo CD Helm chart version installed by this project."
  type        = string
  default     = "9.1.0"
}

variable "application_config_repo_url" {
  description = "Git repository containing the Repo Explorer application-config Helm chart."
  type        = string
  default     = "https://github.com/maneishbisht/REPO_EXPLORER_APPLICATION_CONFIG.git"
}

variable "application_config_repo_revision" {
  description = "Git revision tracked by the bootstrap Argo CD Applications."
  type        = string
  default     = "master"
}

variable "application_config_chart_path" {
  description = "Path to the application-config Helm chart inside its Git repository."
  type        = string
  default     = "."
}
