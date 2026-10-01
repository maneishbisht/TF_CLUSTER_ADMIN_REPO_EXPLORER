variable "aws_region" {
  description = "AWS region containing the EKS clusters."
  type        = string
  default     = "ap-south-1"
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Pinned AWS Load Balancer Controller Helm chart version used by Argo CD Applications."
  type        = string
  default     = "1.14.0"
}

variable "gateway_api_version" {
  description = "Pinned Gateway API CRD release version deployed by Argo CD."
  type        = string
  default     = "1.6.0"
}

variable "secrets_store_csi_driver_chart_version" {
  description = "Pinned Secrets Store CSI Driver Helm chart version used by Argo CD."
  type        = string
  default     = "1.6.0"
}

variable "secrets_store_csi_provider_aws_chart_version" {
  description = "Pinned AWS Secrets Store CSI Provider Helm chart version used by Argo CD."
  type        = string
  default     = "3.1.0"
}

variable "repo_explorer_frontend_config_repo_url" {
  description = "Git repository containing repo-explorer frontend configuration manifests."
  type        = string
  default     = "https://github.com/maneishbisht/REPO_EXPLORER_FRONTEND_CONFIG.git"
}

variable "repo_explorer_frontend_config_repo_path" {
  description = "Path within the frontend configuration repository containing Kubernetes manifests."
  type        = string
  default     = "."
}

variable "repo_explorer_backend_config_repo_url" {
  description = "Git repository containing repo-explorer backend configuration manifests."
  type        = string
  default     = "https://github.com/maneishbisht/REPO_EXPLORER_BACKEND_CONFIG.git"
}

variable "repo_explorer_backend_config_repo_path" {
  description = "Path within the backend configuration repository containing Kubernetes manifests."
  type        = string
  default     = "."
}
