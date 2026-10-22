---
name: vap-live-verification
description: Use when shipping or changing a ValidatingAdmissionPolicy on a live AKS cluster and it must be proven to actually deny. Scratch-copy test with failurePolicy Fail and server-side dry-run requests.
metadata:
  type: skill
  domain: infrastructure
  triggers: ValidatingAdmissionPolicy, VAP, admission policy, allowlist policy, CEL, failurePolicy, dry-run denial
---

# Live Verification of a ValidatingAdmissionPolicy

"Object exists and Argo is Synced" proves nothing. With `failurePolicy: Ignore`, a CEL error or unresolved param silently admits everything. A positive denial on the live cluster is the acceptance test. Cluster access: `/aks-bastion-live-access`.

## Procedure

1. Copy the policy and binding under a scratch name (for example `<name>-scratch`). Set `failurePolicy: Fail` so any evaluation error becomes a visible denial instead of an admit.
2. Bind it with `validationActions: [Deny]`, scoped by `namespaceSelector` label or `metadata.name` on a throwaway or already-sanctioned namespace. Never test in a namespace a client is using.
3. Test the exact shape that ships. A label-scoped scratch binding can pass where the unscoped live binding fails, so repeat against the real binding shape (unscoped, real matchConstraints) before accepting.
4. Fire server-side dry-run requests only: `kubectl create/apply --dry-run=server`. Cover at least: one denied case, one allowed case, one unrelated resource kind (must admit).
5. Params: do not use ConfigMap `paramKind`/`paramRef` on AKS 1.35.x. The param snapshot was observed frozen (new ConfigMaps never found, updates not propagating). Use an inline CEL map/list variable. If a param is unavoidable, set `parameterNotFoundAction: Deny` to expose unresolved params (`Allow` silently skips).
6. Avoid `namespaceObject.metadata.name` on this cluster (errors); use `request.namespace`.
7. Edit propagation: change the inline list in the scratch policy, re-run a dry-run, confirm the new result within seconds.
8. Cleanup: delete scratch policy, binding, and any scratch namespaces. Close the bastion tunnel by recorded PID only (never `pkill` by "bastion" or port; orphaned `az network bastion tunnel` children survive killing the parent; pick another port if one is held).
9. Prod: if elevation (PIM) is needed, a cached az token will not pick up the re-elevation. Ask the user to run `! az login` so it lands in this session. Do not loop on AuthorizationFailed.

## Acceptance

Scratch denial and admit cases pass, shipped shape re-verified, scratch objects removed, tunnel PID closed.
