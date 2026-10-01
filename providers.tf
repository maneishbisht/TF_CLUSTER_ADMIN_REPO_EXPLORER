provider "aws" {
  region = var.aws_region
}

# Terraform must be executed while the operator is already authenticated as
# the cluster-admin-role created by the EKS infrastructure project.

provider "kubernetes" {
  alias = "dev"

  host                   = data.aws_eks_cluster.clusters["dev"].endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.clusters["dev"].certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--region",
      var.aws_region,
      "--cluster-name",
      local.clusters["dev"].cluster_name,
    ]
  }
}

provider "kubernetes" {
  alias = "test"

  host                   = data.aws_eks_cluster.clusters["test"].endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.clusters["test"].certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--region",
      var.aws_region,
      "--cluster-name",
      local.clusters["test"].cluster_name,
    ]
  }
}

provider "kubernetes" {
  alias = "prod"

  host                   = data.aws_eks_cluster.clusters["prod"].endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.clusters["prod"].certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--region",
      var.aws_region,
      "--cluster-name",
      local.clusters["prod"].cluster_name,
    ]
  }
}

provider "helm" {
  alias = "dev"

  kubernetes {
    host                   = data.aws_eks_cluster.clusters["dev"].endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.clusters["dev"].certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        local.clusters["dev"].cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

provider "helm" {
  alias = "test"

  kubernetes {
    host                   = data.aws_eks_cluster.clusters["test"].endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.clusters["test"].certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        local.clusters["test"].cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

provider "helm" {
  alias = "prod"

  kubernetes {
    host                   = data.aws_eks_cluster.clusters["prod"].endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.clusters["prod"].certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        local.clusters["prod"].cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}
