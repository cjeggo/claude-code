---
name: edr-agent-kernel-module-diagnosis
description: Use when an EDR agent on a cloud Ubuntu VM reports "partially protected", "kernel not supported" or a kernel module that fails to load, especially after a kernel update.
metadata:
  type: skill
  domain: infrastructure
  triggers: partially protected, kernel not supported, kernel module not loaded, secure boot module rejected, unavailable key, MOK enrolment
---

# EDR agent kernel module diagnosis

Two causes commonly stack: (1) the running kernel has no module in the agent's content; (2) a module exists but Secure Boot lockdown rejects it because the vendor signing key is not trusted. Check both before concluding.

## Diagnose (read-only)

1. Kernel: `uname -r`; installed kernels `dpkg -l 'linux-image-*' | grep ^ii`.
2. Agent install log (path varies by vendor): grep for the kernel-module extractor line, e.g. "Kernel X not found in config.json". Means cause 1.
3. List kernels the agent content supports: extract the kernel-module archive shipped in the agent content and read its `config.json`. Cross-check the vendor's published kernel table; support is gated by content version.
4. Agent manager log: grep the kernel-module manager lines for load results.
5. Kernel messages, WIDE filter: `sudo dmesg | grep -i -E 'lockdown|unavailable key|module|signature|apparmor|audit'`. Do not pre-exclude lines; "Loading of module with unavailable key is rejected" means cause 2. A hypothesis is only ruled out by a search wide enough to have found it.
6. Secure Boot: `mokutil --sb-state`, `mokutil --list-enrolled`, `mokutil --test-key <vendor cert .der>`.
7. Module signer: extract the module from the archive, `modinfo -F signer <module>`, `modinfo -F vermagic <module>` (must match `uname -r`), and `openssl x509 -inform der -in <cert> -noout -subject -serial`.
8. Do not claim a daemon depends on the module without evidence; check the console and process state separately.

## One-shot test on a supported older kernel

1. Set `GRUB_DEFAULT=saved` in `/etc/default/grub`, run `sudo update-grub`.
2. Read menu entry IDs from `/boot/grub/grub.cfg` (submenu>entry form).
3. `sudo grub-reboot '<submenu id>><entry id>'` then reboot. The next boot only uses it; the following reboot returns to the default order.

## MOK enrolment (proof only)

`sudo mokutil --import <vendor cert .der>`, set a one-time password, reboot, and complete "Enroll MOK" at the VM serial console. Verify the module loads (`lsmod`) and the console shows protected.

## Before recommending rollout

Enrolment makes the kernel trust any module signed by that vendor key, needs interactive console access per host and after each rebuild, and cannot be baked in for marketplace images. Present it as a risk decision for the security owner, with alternatives: vendor content update for the newer kernel, modules signed by a key the distro already trusts, agent user mode (eBPF), or holding the kernel with a written risk acceptance.

## Notes

- Track which host each output came from when comparing machines.
- Keep a verbatim evidence log (command and output) for the security audience.
