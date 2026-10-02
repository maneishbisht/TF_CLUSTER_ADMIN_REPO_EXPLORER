# Root-admin GitHub Actions step: update application-config values

The Root/EKS infrastructure repository should update the three environment values files after the EKS endpoints are known.

The intended secret names are:

```text
REPO_EXPLORER_APPLICATION_CONFIG
CONFIG_REPO_PAT
```

Example step to add to the Root Terraform workflow after the EKS cluster data is available:

```yaml
- name: Update application-config Helm values with EKS endpoints
  env:
    APPLICATION_CONFIG_REPO: ${{ secrets.REPO_EXPLORER_APPLICATION_CONFIG }}
    CONFIG_REPO_PAT: ${{ secrets.CONFIG_REPO_PAT }}
    DEV_CLUSTER_ENDPOINT: ${{ steps.eks_endpoints.outputs.dev_endpoint }}
    TEST_CLUSTER_ENDPOINT: ${{ steps.eks_endpoints.outputs.test_endpoint }}
    PROD_CLUSTER_ENDPOINT: ${{ steps.eks_endpoints.outputs.prod_endpoint }}
  run: |
    set -euo pipefail

    rm -rf /tmp/repo-explorer-application-config

    git clone --depth 1 \
      "https://x-access-token:${CONFIG_REPO_PAT}@${APPLICATION_CONFIG_REPO#https://}" \
      /tmp/repo-explorer-application-config

    cd /tmp/repo-explorer-application-config

    python - <<'PY'
    import os
    import pathlib

    replacements = {
        "values-dev.yaml": os.environ["DEV_CLUSTER_ENDPOINT"],
        "values-test.yaml": os.environ["TEST_CLUSTER_ENDPOINT"],
        "values-prod.yaml": os.environ["PROD_CLUSTER_ENDPOINT"],
    }

    for filename, endpoint in replacements.items():
        path = pathlib.Path(filename)
        lines = path.read_text().splitlines()

        replaced = False
        for index, line in enumerate(lines):
            if line.startswith("  endpoint:"):
                lines[index] = f'  endpoint: "{endpoint}"'
                replaced = True
                break

        if not replaced:
            raise SystemExit(f"target.endpoint not found in {filename}")

        path.write_text("\n".join(lines) + "\n")
    PY

    if git diff --quiet -- values-dev.yaml values-test.yaml values-prod.yaml; then
      echo "No EKS endpoint changes detected."
      exit 0
    fi

    git config user.name "github-actions[bot]"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

    git add values-dev.yaml values-test.yaml values-prod.yaml
    git commit -m "chore: update EKS cluster endpoints"
    git push
```

The exact output step IDs are dependent on the Root Terraform workflow. The important part is that the workflow provides the three EKS API endpoints to the update step.

## Why the test endpoint matters

`test_cluster` does not have its own Argo CD instance. The dev Argo CD instance manages it remotely. Therefore `values-test.yaml` must contain the EKS API endpoint that matches the cluster registration stored in dev Argo CD.

For dev and prod, the child Applications use `https://kubernetes.default.svc` because those targets are the local Argo CD control-plane clusters. The endpoint is still stored in the values file so the environment data remains complete and can be used by other chart resources later.
