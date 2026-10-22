---
name: defender-finding-triage
description: Use when triaging Defender for Cloud recommendations (storage, AKS Azure Policy, VM patching) to decide false positive, deliberate exception, or real fix before ticketing.
metadata:
  type: skill
  domain: security
  triggers: defender finding, defender recommendation, restrict network access, azure policy for kubernetes, missing system updates
---

# Defender for Cloud Finding Triage

1. Classify: false positive (control already met another way), deliberate exception (documented business reason, e.g. database restore tooling), dormant/decommission candidate, out of scope (not yours), or real fix.
2. Check live config read-only (Resource Graph / `az ... show`), not IaC alone. Example: a storage finding is a false positive if public access is disabled and a private endpoint exists.
3. For a real fix, trace the IaC owner and every dependency before proposing the change: consumer pipelines' actual runner tags, CI identity permissions, existing module mechanisms with precedent. Never assume a consumer is on a virtual-network runner.
4. For Azure Policy for Kubernetes findings, list the exact failing pods/services with `az rest --method post --url ".../providers/Microsoft.PolicyInsights/componentPolicyStates/latest/queryResults?api-version=2022-04-01"` and read initiative parameter defaults from the set definition; management-group-scope assignments with default parameters are usually not yours to tune.
5. Verify upstream support (docs/Dockerfile/chart) before proposing non-root changes. Do not propose registry mirroring as a fix, or Pod Security Admission enforce, before images are verified non-root.
6. Ticket only real fixes; write a one-line response for the rest.
