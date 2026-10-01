variable "cluster_key" {
  description = "Logical key for the Argo CD instance that receives the ApplicationSets, such as dev, test, or prod."
  type        = string
}

variable "cluster_name" {
  description = "Actual EKS cluster name containing the Argo CD instance (when enabled in the first project)."
  type        = string
}

variable "aws_region" {
  description = "AWS region containing the EKS clusters."
  type        = string
}

variable "target_clusters" {
  description = "Clusters that the Argo CD ApplicationSets in this cluster should target. Test is empty because Argo CD is not installed there."
  type = list(object({
    cluster_key  = string
    cluster_name = string
    server       = string
  }))
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Pinned AWS Load Balancer Controller Helm chart version."
  type        = string
}

variable "gateway_api_version" {
  description = "Pinned Gateway API release version."
  type        = string
}

variable "secrets_store_csi_driver_chart_version" {
  description = "Pinned Secrets Store CSI Driver Helm chart version."
  type        = string
}

variable "secrets_store_csi_provider_aws_chart_version" {
  description = "Pinned AWS Secrets Store CSI Provider Helm chart version."
  type        = string
}

variable "repo_explorer_frontend_config_repo_url" {
  description = "Frontend configuration Git repository URL."
  type        = string
}

variable "repo_explorer_frontend_config_repo_path" {
  description = "Path within the frontend configuration repository containing Kubernetes manifests."
  type        = string
}

variable "repo_explorer_backend_config_repo_url" {
  description = "Backend configuration Git repository URL."
  type        = string
}

variable "repo_explorer_backend_config_repo_path" {
  description = "Path within the backend configuration repository containing Kubernetes manifests."
  type        = string
}
