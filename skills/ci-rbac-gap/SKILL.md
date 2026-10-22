---
name: ci-rbac-gap
description: Use when a CI job fails with an Azure authorization/403/401 error (AcrPush denied, role assignment missing, "does not have permission to perform action") and the fix is a missing Azure RBAC grant that belongs in your access-control IaC.
metadata:
  type: skill
  domain: infrastructure
  triggers: CI job 403, AcrPush denied, RoleAssignmentExists, missing role assignment, role assignment as code, OIDC service principal permission
---

# CI RBAC Gap - from failing job to access-control change

A CI job fails because the identity it authenticates as lacks an Azure role at the scope it needs. This is distinct from a runner-exhaustion or infrastructure failure. Here the pipeline design is fine - a grant is missing or only ever existed as a manual (portal) change.

## 1. Identify the identity, the missing role, the scope

From the failing job trace:
- Which login step ran (an OIDC federated login, a runner managed identity, a deploy service principal). Note the client ID it used.
- The exact action denied (`Microsoft.ContainerRegistry/registries/push/write` -> `AcrPush`) and the resource it targeted (registry, resource group, subscription) - that is the scope.

## 2. Identity forensics (read-only `az`)

```
az ad sp show --id <appId-or-objectId> --query "{name:displayName, appId:appId, oid:id}"
az role assignment list --assignee <objectId> --all -o table
az role assignment list --scope <resource-id> --query "[].{p:principalName, r:roleDefinitionName, created:createdOn}" -o table
```

Distinguish manual grants from Terraform-created ones: Terraform-created assignments usually have a deterministic GUID name derived from principal, role and scope; manual ones have random GUIDs and often an older `createdOn` unrelated to any apply. A grant that "works in env A but not env B" is usually a manual grant in A that was never carried into IaC.

## 3. Locate or create the role-assignment definition

Find where your access-control IaC keeps grants for this purpose (for example a per-environment YAML or Terraform variable file). If there is **no precedent for where this grant belongs, stop and ask** - do not invent a directory or file name.

Add the grant: principal (a group or managed identity object ID - never a named user), role, and scope (resource-scoped, not resource-group-wide, unless the existing pattern already is).

## 4. Handle a collision with an existing manual assignment

The apply fails with `409 RoleAssignmentExists` if the same principal, role and scope already exists as a manual grant. Two paths:
- **Non-destructive:** add a Terraform `import {}` block so the state adopts the existing assignment. Preferred for production.
- **Delete and recreate:** delete the manual grant (needs explicit per-command user authorization) and let the pipeline recreate it. Simpler for non-production.
Confirm which with the user.

## 5. Finish

- `terraform fmt` and `validate`.
- One change request covering every environment in scope.
- Description: summary and context only. No gating-status editorialising, no rollout mechanics.
- After merge: if merge-request pipelines only cover one environment, each other environment needs its own manual pipeline run.

`→ skipped: a generic "grant any role" helper. The value is the forensics and collision handling, not automation.`
