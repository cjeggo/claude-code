---
name: azure-hub-firewall-diagnostics
description: Use when a VM subnet has silently failing outbound HTTPS (package installs, apt/dpkg, curl to external endpoints) in a hub-and-spoke network with a central Azure Firewall.
metadata:
  type: skill
  domain: infrastructure
  triggers: outbound HTTPS failing, package install timeout, hub firewall, IP group, spoke subnet blocked
---

# Diagnosing Silent Outbound Failures in a Hub-and-Spoke Network

Symptom: a VM in a given subnet can't reach the internet (package installs hang/fail, curl times out) while other subnets work fine. Root cause is almost always the subnet not being a member of the firewall's allow-list, not a VM-level or DNS problem.

## Checklist

1. Identify the hub firewall policy (usually in a central connectivity subscription, owned by the network team).
2. Find the relevant application rule collection group covering the traffic type (e.g. package repos, generic HTTPS egress).
3. Check the rule's `sourceIpGroups`, **not** `sourceAddresses`, if your environment's rules are IP-Group-based.
4. Confirm the failing subnet's CIDR is actually a member of the referenced IP Group. If it isn't, that's the fault - request onboarding from the network team rather than debugging further at the VM level.

`→ skipped: automated CIDR-membership checker, add if this recurs often enough to justify scripting.`
