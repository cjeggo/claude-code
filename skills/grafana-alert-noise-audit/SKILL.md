---
name: grafana-alert-noise-audit
description: Use when auditing or cutting Grafana alert noise - measure firings from alert state history by rule/cluster/namespace, replay against proposed scoping/mutes, apply, then verify with a render/query check.
metadata:
  type: skill
  domain: observability
  triggers: alert noise, too many alerts, on-call readiness, mute rules, notification policy, alert state history
---

# Grafana Alert Noise Audit

1. **Measure from history, not the rule list.** Query the alert state-history datasource (in Grafana Cloud, the `grafanacloud-alert-state-history` Loki datasource) for 28 days of transitions into Alerting; count by rule, cluster, namespace. Also take the last 7 days.
2. **Classify the owner.** Platform namespaces (GitOps controller, monitoring, log shipper, kube-system) belong to the platform team. Application namespaces and database-team rules belong to others - cut or mute only as agreed.
3. **Replay.** Apply the proposed namespace scoping/mutes to the history counts to estimate the reduction. State it as a replay, not a measured before/after; schedule a recount in about a week.
4. **Choose the mechanism.**
   - Rule in a folder used by only one team: scope the query or delete.
   - Rule in a shared folder used by other teams: never delete; add a mute route (mute timing active 24/7) in the notification policy for the affected clusters.
   - Design the final state now. No re-enable toggles for go-live.
5. **Check permissions before writing policy.** Verify provenance and `/api/access-control/user/permissions` (needs `alert.notifications.routes:write`) before explaining any 403.
6. **Apply, then verify.** Re-query state history and confirm remaining firings. Muted rules still evaluate and write state history; only deleted or scoped rules reduce evaluation cost. Do not claim a cost saving without billing data.
7. **Dashboards:** verify every panel by running its query against live data and rendering it. Never use `or vector(0)` in stat tiles (false green); use a NO DATA mapping.
8. If the auto-mode classifier denies a write, stop and hand it to the user.
