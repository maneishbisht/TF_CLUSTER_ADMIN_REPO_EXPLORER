locals {
  clusters = {
    dev = {
      cluster_name = "dev_cluster"
    }

    test = {
      cluster_name = "test_cluster"
    }

    #prod = {
    #  cluster_name = "prod_cluster"
    #}
  }

  # Argo CD is installed only on dev and prod.
  # The dev Argo CD instance is the control plane for both dev and test.
  # Therefore the dev module bootstraps the application-config Helm chart
  # twice: once with values-dev.yaml and once with values-test.yaml.
  # The prod Argo CD instance bootstraps it once with values-prod.yaml.
  application_repositories = {
    dev = [
      {
        name        = "dev"
        values_file = "values-dev.yaml"
      },
      {
        name        = "test"
        values_file = "values-test.yaml"
      }
    ]

    test = []

    #prod = [
    #  {
    #    name        = "prod"
    #    values_file = "values-prod.yaml"
    #  }
    #]
  }
}

# These clusters already exist and were created by the separate EKS
# infrastructure Terraform project.
data "aws_eks_cluster" "clusters" {
  for_each = local.clusters
  name     = each.value.cluster_name
}

module "dev" {
  source = "./modules/cluster"

  cluster_key  = "dev"
  cluster_name = local.clusters["dev"].cluster_name
  aws_region   = var.aws_region

  application_config_repo_url      = var.application_config_repo_url
  application_config_repo_revision = var.application_config_repo_revision
  application_config_chart_path    = var.application_config_chart_path
  application_repositories         = local.application_repositories["dev"]
  argocd_chart_version             = var.argocd_chart_version

  providers = {
    kubernetes = kubernetes.dev
    helm       = helm.dev
  }
}

module "test" {
  source = "./modules/cluster"

  cluster_key  = "test"
  cluster_name = local.clusters["test"].cluster_name
  aws_region   = var.aws_region

  application_config_repo_url      = var.application_config_repo_url
  application_config_repo_revision = var.application_config_repo_revision
  application_config_chart_path    = var.application_config_chart_path
  application_repositories         = local.application_repositories["test"]
  argocd_chart_version             = var.argocd_chart_version

  providers = {
    kubernetes = kubernetes.test
    helm       = helm.test
  }
}

#module "prod" {
#  source = "./modules/cluster"
#
#  cluster_key  = "prod"
#  cluster_name = local.clusters["prod"].cluster_name
#  aws_region   = var.aws_region
#
#  application_config_repo_url      = var.application_config_repo_url
#  application_config_repo_revision = var.application_config_repo_revision
#  application_config_chart_path    = var.application_config_chart_path
#  application_repositories         = local.application_repositories["prod"]
#  argocd_chart_version             = var.argocd_chart_version
#
#  providers = {
#    kubernetes = kubernetes.prod
#    helm       = helm.prod
#  }
#}
