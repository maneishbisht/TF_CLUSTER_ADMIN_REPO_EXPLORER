variable "cluster_key" {
  description = "Logical key for the Argo CD control plane cluster, such as dev, test, or prod."
  type        = string
}

variable "cluster_name" {
  description = "Actual EKS cluster name containing this module's Argo CD control plane."
  type        = string
}

variable "aws_region" {
  description = "AWS region containing the EKS clusters."
  type        = string
  default     = "ap-south-1"
}

variable "application_config_repo_url" {
  description = "Git repository containing the application-config Helm chart."
  type        = string
  default     = "https://github.com/maneishbisht/REPO_EXPLORER_APPLICATION_HELM.git"
}

variable "application_config_repo_revision" {
  description = "Git revision of the application-config Helm chart."
  type        = string
  default     = "master"
}

variable "application_config_chart_path" {
  description = "Path to the Helm chart inside the application-config Git repository."
  type        = string
  default     = "."
}

variable "application_repositories" {
  description = "Target environment bootstrap entries. Each entry selects one values file from the application-config repository."
  type = list(object({
    name        = string
    values_file = string
  }))
}

variable "argocd_chart_version" {
  description = "Pinned Argo CD Helm chart version."
  type        = string
}
