# EKS Cluster Admin / Argo CD ApplicationSet Terraform Project

This project manages Argo CD `ApplicationSet` resources in the already-existing EKS clusters.

The EKS clusters and foundational Kubernetes resources are created by the separate EKS infrastructure Terraform project.

## Ownership boundary

The EKS infrastructure project owns:

- EKS clusters
- `repo-explorer` namespace
- `repo-explorer-backend-sa`
- `gateway-controller-sa`
- Argo CD installation on `dev_cluster` and `prod_cluster`

This project owns:

- Argo CD ApplicationSet for platform controllers
- Argo CD ApplicationSet for repo-explorer configuration repositories

This project no longer installs Argo CD itself, and it no longer installs the AWS Load Balancer Controller or Secrets Store CSI components directly with Terraform Helm releases.

## ApplicationSet design

### Dev Argo CD

The controller ApplicationSet uses Matrix generators for:

```text
[dev_cluster, test_cluster]
        x
[AWS Load Balancer Controller + Gateway API/LBC CRDs,
 AWS Secrets Store CSI Driver + AWS Provider + CSI CRDs]
```

It therefore generates four Applications:

- `dev-aws-lb-controller`
- `test-aws-lb-controller`
- `dev-aws-secrets-store-csi`
- `test-aws-secrets-store-csi`

The repo-explorer ApplicationSet uses:

```text
[dev_cluster, test_cluster]
        x
[REPO_EXPLORER_FRONTEND_CONFIG, REPO_EXPLORER_BACKEND_CONFIG]
```

It therefore generates four Applications as well.

### Prod Argo CD

The controller ApplicationSet uses:

```text
[prod_cluster]
        x
[AWS Load Balancer Controller + Gateway API/LBC CRDs,
 AWS Secrets Store CSI Driver + AWS Provider + CSI CRDs]
```

The repo-explorer ApplicationSet uses:

```text
[prod_cluster]
        x
[REPO_EXPLORER_FRONTEND_CONFIG, REPO_EXPLORER_BACKEND_CONFIG]
```

## Controller Applications

### AWS Load Balancer Controller

Each generated LBC Application has three sources:

1. AWS Load Balancer Controller Helm chart `1.14.0`
2. Standard Gateway API CRDs from Gateway API release `v1.6.0`

The LBC Helm chart is allowed to install its own CRDs (including the controller-specific CRDs). This avoids managing the same LBC CRDs from a second Git source in the same Argo CD Application. AWS documentation requires the standard Gateway API CRDs plus the LBC-specific Gateway CRDs, and the LBC chart contains its CRDs for Helm installation.

The Helm configuration reuses the `gateway-controller-sa` created by the EKS infrastructure project and enables the ALB/NLB Gateway API feature gates.

The AWS Load Balancer Controller documentation states that the current controller supports Gateway API and requires the standard Gateway API CRDs plus the AWS-vended Gateway CRDs. It is built for Gateway API `v1.6.0`.

### AWS Secrets Store CSI

Each generated CSI Application has two Helm sources:

1. Secrets Store CSI Driver `1.6.0`
2. AWS Secrets Store CSI Provider `3.1.0`

The CSI Driver source explicitly configures the token requests required by the AWS provider:

```text
sts.amazonaws.com
pods.eks.amazonaws.com
```

The AWS provider source explicitly sets:

```text
secrets-store-csi-driver.install=false
```

so the provider chart does not attempt to install a second copy of the CSI Driver.

## Argo CD cluster registration prerequisite

The dev Argo CD ApplicationSets intentionally target both `dev_cluster` and `test_cluster`.

Argo CD does **not** create target-cluster credentials merely because an ApplicationSet contains a destination. The target cluster must already be registered in the dev Argo CD instance. Register `test_cluster` with Argo CD using your approved cluster-registration process before expecting the generated test Applications to sync.

The local dev cluster uses:

```text
https://kubernetes.default.svc
```

The test destination is rendered from the live EKS API endpoint discovered by Terraform.

The prod ApplicationSets only target the local prod cluster, so no cross-cluster registration is required for those generated Applications.

## Repository credentials

The two repo-explorer configuration repositories are public URLs in the Terraform configuration, but if access is private in your GitHub organization, register the repositories with the appropriate Argo CD instance(s) manually using the agreed `argocd repo add` process.

Terraform does not inject GitHub PATs into Argo CD.

The repo ApplicationSets default to the repository root (`.`) and recursively process manifests. Change the corresponding Terraform path variables when the Kubernetes manifests live under a subdirectory.

## Authentication

Run this project while the operator has already assumed the `cluster-admin-role` from the EKS infrastructure project.

The Kubernetes provider uses:

```text
aws eks get-token
```

The provider does not assume the admin role itself.

## Apply order

1. Apply the EKS infrastructure project.
2. Confirm that Argo CD is running in dev and prod.
3. Register the test EKS cluster in the dev Argo CD instance.
4. Register the private repo credentials with the dev/prod Argo CD instances as required.
5. Apply this project to create the ApplicationSets.
6. Verify the generated Applications in each Argo CD instance.

## Versions

- AWS Load Balancer Controller Helm chart: `1.14.0`
- Gateway API CRDs: `v1.6.0`
- Secrets Store CSI Driver: `1.6.0`
- AWS Secrets Store CSI Provider: `3.1.0`

## References

- Argo CD Matrix generator: https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Matrix/
- Argo CD generator templates: https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Template/
- Argo CD List generator: https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-List/
- Argo CD multiple sources: https://argo-cd.readthedocs.io/en/latest/user-guide/multiple_sources/
- AWS Load Balancer Controller Gateway API: https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/guide/gateway/gateway.md
- AWS Secrets Store CSI Provider: https://github.com/aws/secrets-store-csi-driver-provider-aws/blob/main/README.md
