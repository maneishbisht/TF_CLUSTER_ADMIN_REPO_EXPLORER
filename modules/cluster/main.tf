locals {
  install_argocd = length(var.application_repositories) > 0
}

# =============================================================================
# 1. Argo CD INSTALLATION
# =============================================================================
#
# dev  -> Argo CD installed
# test -> Argo CD NOT installed (repository array is empty)
# prod -> Argo CD installed
#
resource "helm_release" "argocd" {
  count = local.install_argocd ? 1 : 0

  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  timeout         = 900
  wait            = true
  cleanup_on_fail = true

  set {
    name  = "configs.cm.create"
    value = "true"
  }

  set {
    name  = "configs.params.create"
    value = "true"
  }

  set {
    name  = "configs.rbac.create"
    value = "true"
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

}

# =============================================================================
# 2. Bootstrap Applications for the application-config Helm chart
# =============================================================================

resource "kubernetes_manifest" "application_config" {
  for_each = {
    for repository in var.application_repositories : repository.name => repository
  }

  depends_on = [helm_release.argocd]
  
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "${var.cluster_key}-application-config-${each.value.name}"
      namespace = "argocd"
    }

    spec = {
      project = "default"

      source = {
        repoURL        = var.application_config_repo_url
        targetRevision = var.application_config_repo_revision
        path           = var.application_config_chart_path

        helm = {
          valueFiles = [
            each.value.values_file
          ]
        }
      }

      # The bootstrap Application itself is stored in the same cluster where
      # Argo CD runs. Its child Applications (rendered by the chart) decide
      # the actual workload destination from the selected values file.
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }

        syncOptions = [
          "ServerSideApply=true"
        ]
      }
    }
  }
}
