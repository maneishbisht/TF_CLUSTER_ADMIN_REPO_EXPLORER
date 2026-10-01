terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"

      configuration_aliases = [
        kubernetes
      ]
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"

      configuration_aliases = [
        helm
      ]
    }
  }
}