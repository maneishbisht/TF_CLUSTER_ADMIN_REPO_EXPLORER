locals {
  clusters = {
    dev = {
      cluster_name = "dev_cluster"
    }

    test = {
      cluster_name = "test_cluster"
    }

    prod = {
      cluster_name = "prod_cluster"
    }
  }

  # Argo CD is installed by the first Terraform project only on dev and prod.
  # The dev Argo CD instance manages dev + test; the prod Argo CD instance
  # manages prod.
  argocd_target_clusters = {
    dev = [
      {
        cluster_key  = "dev"
        cluster_name = local.clusters["dev"].cluster_name
        server       = "https://kubernetes.default.svc"
      },
      {
        cluster_key  = "test"
        cluster_name = local.clusters["test"].cluster_name
        server       = data.aws_eks_cluster.clusters["test"].endpoint
      }
    ]

    test = []

    prod = [
      {
        cluster_key  = "prod"
        cluster_name = local.clusters["prod"].cluster_name
        server       = "https://kubernetes.default.svc"
      }
    ]
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

  target_clusters = local.argocd_target_clusters["dev"]

  aws_load_balancer_controller_chart_version   = var.aws_load_balancer_controller_chart_version
  gateway_api_version                           = var.gateway_api_version
  secrets_store_csi_driver_chart_version       = var.secrets_store_csi_driver_chart_version
  secrets_store_csi_provider_aws_chart_version = var.secrets_store_csi_provider_aws_chart_version

  repo_explorer_frontend_config_repo_url  = var.repo_explorer_frontend_config_repo_url
  repo_explorer_frontend_config_repo_path = var.repo_explorer_frontend_config_repo_path
  repo_explorer_backend_config_repo_url   = var.repo_explorer_backend_config_repo_url
  repo_explorer_backend_config_repo_path  = var.repo_explorer_backend_config_repo_path

  providers = {
    kubernetes = kubernetes.dev
    helm = helm.dev
  }
}

module "test" {
  source = "./modules/cluster"

  cluster_key  = "test"
  cluster_name = local.clusters["test"].cluster_name
  aws_region   = var.aws_region

  target_clusters = local.argocd_target_clusters["test"]

  aws_load_balancer_controller_chart_version   = var.aws_load_balancer_controller_chart_version
  gateway_api_version                           = var.gateway_api_version
  secrets_store_csi_driver_chart_version       = var.secrets_store_csi_driver_chart_version
  secrets_store_csi_provider_aws_chart_version = var.secrets_store_csi_provider_aws_chart_version

  repo_explorer_frontend_config_repo_url  = var.repo_explorer_frontend_config_repo_url
  repo_explorer_frontend_config_repo_path = var.repo_explorer_frontend_config_repo_path
  repo_explorer_backend_config_repo_url   = var.repo_explorer_backend_config_repo_url
  repo_explorer_backend_config_repo_path  = var.repo_explorer_backend_config_repo_path

  providers = {
    kubernetes = kubernetes.test
    helm = helm.test
  }
}

module "prod" {
  source = "./modules/cluster"

  cluster_key  = "prod"
  cluster_name = local.clusters["prod"].cluster_name
  aws_region   = var.aws_region

  target_clusters = local.argocd_target_clusters["prod"]

  aws_load_balancer_controller_chart_version   = var.aws_load_balancer_controller_chart_version
  gateway_api_version                           = var.gateway_api_version
  secrets_store_csi_driver_chart_version       = var.secrets_store_csi_driver_chart_version
  secrets_store_csi_provider_aws_chart_version = var.secrets_store_csi_provider_aws_chart_version

  repo_explorer_frontend_config_repo_url  = var.repo_explorer_frontend_config_repo_url
  repo_explorer_frontend_config_repo_path = var.repo_explorer_frontend_config_repo_path
  repo_explorer_backend_config_repo_url   = var.repo_explorer_backend_config_repo_url
  repo_explorer_backend_config_repo_path  = var.repo_explorer_backend_config_repo_path

  providers = {
    kubernetes = kubernetes.prod
    helm = helm.prod
  }
}
