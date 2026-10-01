output "cluster_names" {
  description = "EKS clusters targeted by this add-ons project."
  value = {
    for key, cluster in local.clusters : key => cluster.cluster_name
  }
}

output "application_set_clusters" {
  description = "Clusters in which this project creates Argo CD ApplicationSets."
  value       = ["dev", "prod"]
}
