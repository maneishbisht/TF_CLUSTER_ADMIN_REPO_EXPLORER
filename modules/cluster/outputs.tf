output "cluster_key" {
  description = "Logical key for the Argo CD instance receiving the ApplicationSets."
  value       = var.cluster_key
}

output "cluster_name" {
  description = "EKS cluster containing the Argo CD instance."
  value       = var.cluster_name
}

output "application_sets_created" {
  description = "Whether this module instance created the controller and repo-explorer ApplicationSets."
  value       = local.create_application_sets
}
