locals {
  target_cluster_elements = [
    for target in var.target_clusters : {
      clusterKey  = target.cluster_key
      clusterName = target.cluster_name
      server      = target.server
    }
  ]

  repo_elements = [
    {
      repoKey = "frontend"
      repoURL = var.repo_explorer_frontend_config_repo_url
      repoPath = var.repo_explorer_frontend_config_repo_path
    },
    {
      repoKey = "backend"
      repoURL = var.repo_explorer_backend_config_repo_url
      repoPath = var.repo_explorer_backend_config_repo_path
    }
  ]

  create_application_sets = length(var.target_clusters) > 0
}

# =============================================================================
# 1. Controller ApplicationSet
# =============================================================================
#
# For the dev Argo CD instance:
#   [dev_cluster, test_cluster] x
#   [AWS Load Balancer Controller + Gateway API/LBC CRDs,
#    AWS Secrets Store CSI Driver + AWS Provider + CSI CRDs]
#
# For the prod Argo CD instance:
#   [prod_cluster] x the same two controller types.
#
# The Matrix generator creates every combination of its two child generators.
# Generator-level templates are used because the two controller Applications
# have different multi-source definitions.
#
resource "kubernetes_manifest" "controllers_applicationset" {
  count = local.create_application_sets ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"

    metadata = {
      name      = "${var.cluster_key}-platform-controllers"
      namespace = "argocd"
    }

    spec = {
      goTemplate = true
      goTemplateOptions = [
        "missingkey=error"
      ]

      generators = [
        {
          matrix = {
            generators = [
              {
                list = {
                  elements = local.target_cluster_elements
                }
              },
              {
                list = {
                  elements = [
                    {
                      component = "aws-lb-controller"
                    }
                  ]
                }
              }
            ]

            template = {
              spec = {
                sources = [
                  {
                    repoURL        = "https://aws.github.io/eks-charts"
                    chart          = "aws-load-balancer-controller"
                    targetRevision = var.aws_load_balancer_controller_chart_version

                    helm = {
                      releaseName = "aws-load-balancer-controller"
                      skipCrds    = false
                      values = <<-EOT
                        clusterName: {{.clusterName}}
                        region: ${var.aws_region}
                        serviceAccount:
                          create: false
                          name: gateway-controller-sa
                        controllerConfig:
                          featureGates:
                            ALBGatewayAPI: true
                            NLBGatewayAPI: true
                      EOT
                    }
                  },
                  {
                    repoURL        = "https://github.com/kubernetes-sigs/gateway-api.git"
                    targetRevision = "v${var.gateway_api_version}"
                    path           = "config/crd/standard"
                  },
                ]
              }
            }
          }
        },
        {
          matrix = {
            generators = [
              {
                list = {
                  elements = local.target_cluster_elements
                }
              },
              {
                list = {
                  elements = [
                    {
                      component = "aws-secrets-store-csi"
                    }
                  ]
                }
              }
            ]

            template = {
              spec = {
                sources = [
                  {
                    repoURL        = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
                    chart          = "secrets-store-csi-driver"
                    targetRevision = var.secrets_store_csi_driver_chart_version

                    helm = {
                      releaseName = "csi-secrets-store"
                      values = <<-EOT
                        tokenRequests:
                          - audience: sts.amazonaws.com
                          - audience: pods.eks.amazonaws.com
                      EOT
                    }
                  },
                  {
                    repoURL        = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
                    chart          = "secrets-store-csi-driver-provider-aws"
                    targetRevision = var.secrets_store_csi_provider_aws_chart_version

                    helm = {
                      releaseName = "secrets-provider-aws"
                      values = <<-EOT
                        secrets-store-csi-driver:
                          install: false
                      EOT
                    }
                  }
                ]
              }
            }
          }
        }
      ]

      template = {
        metadata = {
          name = "{{.clusterKey}}-{{.component}}"
        }

        spec = {
          project = "default"

          destination = {
            server    = "{{.server}}"
            namespace = "kube-system"
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
  }
}

# =============================================================================
# 2. Repo-explorer ApplicationSet
# =============================================================================
#
# For dev:
#   [dev_cluster, test_cluster] x
#   [REPO_EXPLORER_FRONTEND_CONFIG, REPO_EXPLORER_BACKEND_CONFIG]
#
# For prod:
#   [prod_cluster] x the same two repositories.
#
resource "kubernetes_manifest" "repo_explorer_applicationset" {
  count = local.create_application_sets ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"

    metadata = {
      name      = "${var.cluster_key}-repo-explorer"
      namespace = "argocd"
    }

    spec = {
      goTemplate = true
      goTemplateOptions = [
        "missingkey=error"
      ]

      generators = [
        {
          matrix = {
            generators = [
              {
                list = {
                  elements = local.target_cluster_elements
                }
              },
              {
                list = {
                  elements = local.repo_elements
                }
              }
            ]
          }
        }
      ]

      template = {
        metadata = {
          name = "{{.clusterKey}}-repo-explorer-{{.repoKey}}"
        }

        spec = {
          project = "default"

          source = {
            repoURL        = "{{.repoURL}}"
            targetRevision = "HEAD"
            path           = "{{.repoPath}}"

            directory = {
              recurse = true
            }
          }

          destination = {
            server    = "{{.server}}"
            namespace = "repo-explorer"
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
  }
}
