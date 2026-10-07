output "cluster_names" {
  description = "EKS clusters targeted by this Argo CD bootstrap project."
  value = {
    for key, cluster in local.clusters : key => cluster.cluster_name
  }
}

output "argocd_installed_clusters" {
  description = "Clusters where this project installs Argo CD."
  # value       = ["dev", "prod"]
  value       = ["dev", "prod"]
}

output "application_config_bootstrap" {
  description = "Bootstrap Helm values files applied by each Argo CD control plane."
  value = {
    for key, repositories in local.application_repositories : key => [
      for repository in repositories : repository.values_file
    ]
  }
}
