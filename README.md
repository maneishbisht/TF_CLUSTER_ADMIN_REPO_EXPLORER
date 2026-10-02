# CLUSTER_ADMIN_TF — Argo CD Control-Plane Bootstrap

This Terraform project owns the **Argo CD control-plane installation and bootstrap only** for the already-existing EKS clusters.

The separate EKS infrastructure Terraform project owns the EKS clusters and the foundational Kubernetes resources such as:

- `repo-explorer` namespace
- `repo-explorer-backend-sa`
- `gateway-controller-sa`
- EKS IAM / IRSA resources

The separate `REPO_EXPLORER_APPLICATION_CONFIG` Git repository owns the application manifests for:

- AWS Load Balancer Controller + Gateway API CRDs
- AWS Secrets Store CSI Driver + AWS provider
- Repo Explorer frontend configuration repository
- Repo Explorer backend configuration repository

Those resources are delivered through Argo CD Applications defined by the Helm chart.

## Ownership after the refactor

### This Terraform project owns

- Argo CD Helm installation on `dev_cluster`
- Argo CD Helm installation on `prod_cluster`
- Bootstrap `Application` objects in those Argo CD instances

### The application-config Helm repository owns

- The per-cluster values files
- Platform dependency Application manifests
- Config-repository Application manifests
- Application sync policies

### The EKS infrastructure project owns

- EKS clusters
- IAM roles / EKS access
- The service accounts referenced by the platform charts
- Other foundational resources required before Argo CD applications are synchronized

## Control-plane model

`test_cluster` does **not** run Argo CD.

The `dev_cluster` Argo CD instance is the control plane for both:

- `dev_cluster`
- `test_cluster`

Therefore the dev Terraform module bootstraps the application-config chart twice:

```text
dev Argo CD
  ├── dev-application-config-dev  -> values-dev.yaml
  └── dev-application-config-test -> values-test.yaml
                                    |
                                    +--> child Applications target test_cluster
```

The prod Argo CD instance only bootstraps:

```text
prod Argo CD
  └── prod-application-config-prod -> values-prod.yaml
```

The test Terraform module receives an empty application repository array, so it creates neither Argo CD nor an application-config bootstrap Application.

## Terraform module repository arrays

The root `main.tf` deliberately contains the environment mapping requested for this architecture:

```text
dev  -> [ dev(values-dev.yaml), test(values-test.yaml) ]
test -> [ ]
prod -> [ prod(values-prod.yaml) ]
```

The array is not the frontend/backend config repository list. It is the list of **application-config Helm chart instances** that the local Argo CD control plane should bootstrap.

## New application-config Helm repository

The repository is expected at:

```text
https://github.com/maneishbisht/REPO_EXPLORER_APPLICATION_CONFIG.git
```

Change the Terraform variable / GitHub secret if the repository uses a different URL.

The chart has:

```text
Chart.yaml
values.yaml
values-dev.yaml
values-test.yaml
values-prod.yaml
templates/
```

The environment values files contain the cluster-specific values that previously lived inside Terraform ApplicationSet templates, including:

- EKS cluster name
- EKS API endpoint
- AWS region
- platform chart versions
- `gateway-controller-sa`
- frontend config repository URL/path
- backend config repository URL/path

The root-admin Terraform GitHub Actions workflow is responsible for updating the EKS endpoints in those files after the EKS cluster data is available.

## Argo CD repository credentials

The GitHub Actions workflow for this project expects the following secrets:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN          # only when the initial AWS identity is temporary
CLUSTER_ADMIN_ROLE_ARN
REPO_EXPLORER_APPLICATION_CONFIG
REPO_EXPLORER_FRONTEND_CONFIG
REPO_EXPLORER_BACKEND_CONFIG
CONFIG_REPO_PAT
```

`REPO_EXPLORER_APPLICATION_CONFIG` is the Git URL of the new Helm chart repository.

The workflow registers the new application-config repository in both dev and prod Argo CD before the bootstrap Applications are created. It also registers the existing frontend/backend configuration repositories because the child Applications in the Helm chart consume those repositories.

## Apply sequence

The GitHub Actions workflow intentionally uses two Terraform applies:

1. `-target` installs Argo CD in dev and prod so the `argoproj.io/v1alpha1/Application` CRD exists.
2. The workflow installs the Argo CD CLI, registers `test_cluster` with dev Argo CD, and registers the three Git repositories.
3. A normal `terraform apply` creates the bootstrap Applications.
4. Argo CD renders the application-config Helm chart and creates/synchronizes the child Applications.

This preserves the required dependency ordering without Terraform owning the child ApplicationSets/Application manifests.

## Important state isolation

Keep this project's S3 backend state key separate from every other Terraform project.

Current key:

```text
clusteradminrepoexplorer.tfstate
```

Do not point this project and the Root/EKS infrastructure project at the same state key. Each Terraform state file must represent one project's resource ownership.

## Root-admin endpoint update

The file `docs/ROOT_ADMIN_GITHUB_ACTION.md` contains the GitHub Actions step to clone the application-config repository, update `values-dev.yaml`, `values-test.yaml`, and `values-prod.yaml` with the current EKS endpoints, and commit/push only when a value changed.

## Validation

Before the first deployment:

1. Make sure the EKS infrastructure project has completed.
2. Make sure `gateway-controller-sa` and the other foundational service accounts exist.
3. Make sure the new application-config repository is reachable using the PAT registered with Argo CD.
4. Run this project's workflow.
5. Verify the bootstrap Applications in the dev and prod Argo CD instances.
6. Verify the generated child Applications for LBC, CSI, frontend, and backend repositories.

## Migration from the previous ApplicationSet Terraform resources

The previous version of this project managed `ApplicationSet` resources directly. After upgrading, Terraform will plan to remove those old resources because their declarations are no longer present. The new Helm chart creates child `Application` objects with new names to avoid an ownership collision while the old ApplicationSets are being removed.

Do not manually recreate the old ApplicationSets after applying this refactor.
