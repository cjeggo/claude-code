---
name: terraform-private-endpoint-import
description: Use when importing an Azure resource that is only reachable from inside the VNet (private endpoints, no public plane) into Terraform state.
metadata:
  type: skill
  domain: infrastructure
  triggers: terraform import, private endpoint, VNet-only resource, no public access
---

# Terraform Import via MR Pipeline (Private Endpoint Resources)

Your local machine cannot reach a private-endpoint-only resource, but the MR pipeline's runner is network-connected and can. Use the pipeline itself as the import execution environment.

## Steps

1. Add native Terraform `import {}` blocks for the target resource(s) to a temporary file (e.g. `_import.tf`) in the project.
2. **Check what region/env the MR pipeline actually targets by default.** Most projects here default their MR pipeline to `integration` - if the resource being imported lives in a different region/env, the auto-triggered MR pipeline will not touch it at all. If the default doesn't already match, temporarily change the pipeline's default `region`/`env` inputs (in `.gitlab-ci.yml`'s `spec.inputs`) to the target region/env, in the same commit or a follow-up commit on this branch.
3. Open a **draft** MR with that file (and the temporary pipeline default change, if needed).
4. Let the MR pipeline run - its plan/apply step executes the import against the real resource from the network-connected runner, now correctly targeting the right region/env.
5. Confirm the import succeeded (check the pipeline output / `terraform state show`).
6. Delete the temporary import file **and revert the temporary pipeline default change** before merging - both are one-time mechanisms, not something to keep in the codebase. Verify the reverted default matches what it was before step 2.

`→ skipped: local az role grant + local import, add only if a resource genuinely needs importing outside CI (rare, ARM APIs are public but data-plane isn't).`
