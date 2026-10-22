---
name: terraform-state-account-private-only
description: Use when making a Terraform state-backend storage account private-endpoint-only (public access disabled) without breaking the consumers that use it as backend.
metadata:
  type: skill
  domain: infrastructure
  triggers: state account private, disable public network access, tfstate storage account
---

# Make a Terraform state storage account private-endpoint-only

Order matters: consumers must plan over the private path before public access is closed, or the pipeline loses its backend.

1. **Enumerate consumers** (every project whose backend points at the account) and their CI scope. Usually only the plan, apply, destroy and refresh jobs touch the backend; format, validate, docs and lint jobs do not and are unaffected.
2. **Move consumers to a runner inside the virtual network** that can reach the endpoint. Check how your pipeline template selects the runner (for example a CI variable scoped per environment); a scope with no variable may fall back to a default of the wrong region. Add the scope explicitly. When triggering pipelines with typed inputs through the API, send `inputs` as a nested JSON object and confirm the resolved pipeline name, because bracket-notation form fields silently fall back to defaults.
3. **Prove plans report "No changes" with public access still open** on the new runner.
4. **Create a narrow custom role for endpoint approval**: the approval action plus `privateEndpointConnections/read`, scoped to the account only, assigned to the identity that creates the endpoint. Caveat: a new role definition can race its own assignment in the same apply and the first apply fails with "could not find role" - trigger a fresh pipeline (never retry the apply job, the saved plan is stale).
5. **Create the blob private endpoint** through your landing-zone or networking IaC (cross-subscription if the account lives elsewhere). Verify the connection state is Approved and check the zone group on the endpoint.
6. **DNS:** do not assume auto-registration. List zone groups on existing endpoints for the same private DNS zone; if none exist, the A record may be a manual step owned by whichever team manages the zone.
7. **Disable public access** (public network access Disabled, default action Deny, shared key off) - only with explicit sign-off. If done in the portal, record the account as IaC debt.
8. **Re-prove every consumer** plans "No changes" via the private path. Then check that any cloud-security finding such as "Storage accounts should restrict network access using virtual network rules" clears (it can lag).

State facts in the change request, not "if X fails" fallbacks: verify with `az` first.
