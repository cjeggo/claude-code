---
name: aks-bastion-live-access
description: Use when live kubectl access to a private AKS cluster is needed for diagnostics (pod status, config verification, synthetic test payloads) and no tunnel is already open.
metadata:
  type: skill
  domain: infrastructure
  triggers: aks bastion, private cluster access, kubectl no route, live pod diagnostics, kubeconfig
---

# Live kubectl Access to a Private AKS Cluster via Azure Bastion

Private AKS clusters have no public API server endpoint. `az aks bastion` opens a tunnel and writes a temporary kubeconfig - this works directly from a local shell. Several false starts (subshell dying on EOF, port conflicts, wrong debug-port hostname) make this non-obvious; this skill captures the working sequence.

## Checklist

1. Look up the resource group, cluster name, and Bastion resource ID (your platform's AKS access runbook, or `az network bastion show`).
2. Run backgrounded with stdin fed by a bounded keepalive - without live stdin the subshell hits EOF and tears the tunnel down within seconds. Never use `yes ""` for this: it spins a core at 100% and is left behind when the `az` side dies:
   `(while sleep 30; do echo; done) | az aks bastion --resource-group <rg> --name <cluster> --bastion <bastion-resource-id> --port <local-port> --yes > /tmp/aks-bastion.log 2>&1 &` (use the shell tool's background mode). If `az` exits, the loop takes SIGPIPE on its next echo (at most 30s) and ends on its own.
3. Read the log for `Setting env var KUBECONFIG to '<temp-path>/.kube/config'`. That path is valid as long as the backgrounded process is alive.
4. First `kubectl` call against that `KUBECONFIG` triggers a `kubelogin` device-code challenge (`login.microsoft.com/device` + code) - the user must complete sign-in once, in their own browser. The token then caches to disk; later calls in-session don't re-prompt.
5. `az aks command invoke` may be disabled on hardened clusters (`DisableRunCommand`) - don't rely on it as a shortcut.
6. To reach a specific in-cluster port (e.g. an operator debug endpoint) rather than the API server, `kubectl port-forward` through the same kubeconfig, not a second bastion tunnel.
7. **Teardown is mandatory when diagnostics finish, and before starting a retry on the same port.** Record the PIDs of the processes you started (the `az aks bastion` process, its keepalive loop, and the child `az network bastion tunnel` process that holds the port, found with `lsof -nP -iTCP:<local-port> -sTCP:LISTEN`) and kill only those. Confirm nothing of yours is left, and restore the previous az default subscription. Do not stack a new tunnel on top of a failed one - clean up first.

`→ skipped: wrapper script automating steps 1-3, add if this recurs enough to justify it.`

## Gotchas

- The tunnel command omits `--subscription`; it fails with exit code 3 unless the az default subscription is the cluster's subscription. Run `az account set` first and restore the previous default afterwards.
- Never kill tunnels by pattern (`pkill -f`, or a loop over `ps | grep bastion`): that also kills any tunnel the user has open on the same machine. Orphaned `az network bastion tunnel` children survive killing the parent, so kill them by their recorded PID. If a port is already held by something you did not start, choose a different local port.
- A cached `az` token does not pick up a role re-elevation (for example PIM). If a lookup returns `AuthorizationFailed` right after the user re-elevated, ask them to log out and back in so the new token lands in your session. Do not retry in a loop.
