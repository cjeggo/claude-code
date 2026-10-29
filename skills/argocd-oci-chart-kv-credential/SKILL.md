---
name: argocd-oci-chart-kv-credential
description: Deploy a vendor Helm chart from a private OCI registry via ArgoCD where the registry credential and chart secrets come from a cloud key vault through the CSI driver. Use when Argo reports ComparisonError on an OCI source, or when designing the credential/consumer split.
---

# ArgoCD OCI chart with a key-vault-synced credential

## Core rule
Never put the chart that provides a credential and the chart that needs it in one Argo Application. Argo renders every source before syncing any, so the render fails (ComparisonError) before the credential exists. Use two Applications: a "secrets" Application first, the vendor chart second.

## Steps
1. Secrets chart (own Application): a SecretProviderClass with `secretObjects` that produces (a) the Argo repository Secret (label `argocd.argoproj.io/secret-type: repository`, type `helm`, `enableOCI: "true"`, url, username, password) and (b) any chart secrets.
2. CSI only creates synced Secrets while a pod mounts the SecretProviderClass. Add a small "holder" pod/Deployment that mounts it.
3. Identity: workload-identity ServiceAccount in the target namespace with a federated credential on the managed identity. Confirm the infra repo actually applies federated credential config (read the module/locals) before relying on a config block; if created by hand, record it as IaC debt.
4. Vendor chart Application: reference the synced Secret via the chart's `existingSecret`-style values. If the chart has no such option, state which values are committed and why.
5. Namespace: vendor agents often need privileged Pod Security Admission and an AppProject allowlist entry for the namespace and repo; set both in the platform config.
6. Ignore drift on Job/CronJob specs in the ApplicationSet if the vendor agent self-updates.

## Diagnosing ComparisonError
- Read the Application conditions and repo-server logs: "authentication required" means the repo Secret is missing or the secrets Application has not synced; check the holder pod and SecretProviderClass events.
- Check the Secret's label and `enableOCI` first, then the key vault secret names/fields.

## Related trap: write passes preflight, fails at data plane
A pipeline that writes to a private-endpoint key vault can pass control-plane (ARM) preflight on the wrong runner and then hang or fail at the vault endpoint. Always list every pipeline input that differs per environment, including the runner.
