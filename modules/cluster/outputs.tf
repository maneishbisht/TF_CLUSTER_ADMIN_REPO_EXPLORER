output "cluster_key" {
  description = "Logical key for this Argo CD control plane module."
  value       = var.cluster_key
}

output "cluster_name" {
  description = "EKS cluster containing this Argo CD control plane."
  value       = var.cluster_name
}

output "argocd_installed" {
  description = "Whether this module installed Argo CD."
  value       = local.install_argocd
}

output "bootstrap_values_files" {
  description = "Helm values files bootstrapped by this control plane."
  value       = [for repository in var.application_repositories : repository.values_file]
}
