---
name: cortex-k8s-scan-trigger
description: Use when you need to force a Cortex Kubernetes connector host scan or inventory collection on an AKS cluster now, instead of waiting for the cortex-job-orchestrator CronJob, and watch it finish.
---

# Trigger and Watch a Cortex Host Scan

The connector's `cortex-job-orchestrator` CronJob in namespace `panw` creates the `cortex-inventory-collector` and `cortex-host-scanner` jobs twice a day. Each node carries an annotation `paloaltonetworks.com/last-scan-trigger`, and the orchestrator skips a node whose last scan is recent. To scan now, clear the annotation on the target nodes and run the CronJob once.

## Checklist

1. Get a tunnel with `/aks-bastion-live-access`. Mutating a prod cluster is a separate decision: ask for explicit sign-off first. Nonprod is fine.
2. Clear the annotation on the nodes to scan (the trailing `-` removes it): `kubectl annotate node <node> paloaltonetworks.com/last-scan-trigger-`
3. Run the orchestrator once: `kubectl create job manual-scan-<tag> --from=cronjob/cortex-job-orchestrator -n panw`
4. Watch: `kubectl get jobs,pods -n panw | grep -E "scanner|inventory"`. Success is the host-scanner pods reaching `Completed` and the node annotation getting a fresh timestamp. Orchestrator logs show `Creating job`, constraint checks, and `sending status`.
5. Clean up: delete your manual Job when done and kill your tunnel by recorded PID.

## Gotchas

- The host-scanner pod shows `0/3 Completed` with a restart count of 3 to 9, and `kubectl get events` shows `BackOff` on `compliance-node-scanner`. That is benign: it is a native sidecar init container (`restartPolicy: Always`) that runs once and exits 0. Judge the scan by the pod phase and the annotation, not the restart count or the event.
- The Nodes view in Cortex lists the scanned nodes with decimal VMSS instance IDs (`vmss00000f` appears as `vmss_15`). The Assets/inventory screen is a different data source, so nodes missing from it do not mean the scan failed.
- Connection-lost rows under Endpoints for old pool IDs are usually stale registrations from rebuilt nodes.
