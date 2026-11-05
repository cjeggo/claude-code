---
name: apt-stale-partial-index
description: Use when apt-get update fails on one repository with "File has unexpected size" or a hash mismatch while curl of the same index URL returns a fresh, valid file. Typically also breaks cloud patch-assessment agents.
metadata:
  type: skill
  domain: infrastructure
  triggers: apt-get update unexpected size, InRelease mismatch, patch assessment failed, stale apt lists partial
---

# apt stale partial index

Symptom: `apt-get update` fails for a single repo (`File has unexpected size (X != Y). Mirror sync in progress?`) while `curl` of the same `InRelease` returns a good file. Patch-assessment agents that call `apt-get update` then report Failed.

Cause: a stale file in `/var/lib/apt/lists/partial`. apt resumes the download with a `Range`/`If-Range` request and treats the stale file as complete.

## Diagnose

1. Run `sudo apt-get update -o Debug::Acquire::https=true` and look for a `Range:` / `If-Range:` request header on the failing repo.
2. List the stale files as root (the directory is root-only, so the glob must expand under root): `sudo sh -c 'ls -l /var/lib/apt/lists/partial/*'`. Note old modification dates.
3. Confirm the origin is healthy: `curl -sI <repo InRelease URL>`.

## Fix

1. Move the partial files aside, do not delete: `sudo sh -c 'mkdir -p /root/apt-partial-aside && mv /var/lib/apt/lists/partial/* /root/apt-partial-aside/'`
2. Re-run `sudo apt-get update`; it should complete clean.
3. Retrigger the platform assessment and wait for it to finish before reading the result.

## Notes

- Track which host each output came from when comparing several machines.
- Check every host in a fleet; the same stale file often exists on more than one.
