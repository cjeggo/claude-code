# CLAUDE.md Template

Copy this into a new project's root as `CLAUDE.md` and fill in the Project Context section. The general preferences and constraints sections apply to all projects unless overridden.

---

# CLAUDE.md

## Maintaining This File

Ask before adding anything to this file - do not add unilaterally. If something already here turns out to be wrong or has changed, call it out explicitly so it can be corrected. This file drifts as projects evolve; keeping it accurate is an active responsibility.

---

## Project Context

> **Fill this in for each project.**

### What This Project Is

_Describe the system, product, or domain being worked on._

### Repository / Directory Structure

_Describe the local directory layout, any monorepo structure, and how it maps to remote repos._

### Key Technologies

_Languages, frameworks, cloud provider, IaC tooling, CI/CD platform, etc._

### Active Workstreams

_Link to Obsidian workstream notes or summarise what is currently in flight._

### Constraints Specific to This Project

_Any project-level tool access restrictions, read-only systems, deployment gates, etc._

### Regulatory Context

_Which standards apply: PCI DSS, DORA, NIS2, SOC 2, HIPAA, or other. ISO 27001 always applies._

---

## Obsidian as the Project Brain

All notes, drafts, trackers, and context live in Obsidian at the path specified below. Do not create tracking markdown files in the repo root.

**Vault path for this project:** `_fill in_`

- Use the obsidian-vault MCP to read and write notes. Ask if the MCP is not available.
- Use backlinks (`[[Note Name]]`) to build knowledge graphs between related notes.
- Do not copy external documentation (e.g. Confluence pages) into Obsidian - draft content there, link to the source.
- After completing meaningful work, update the Achievement Tracking note. Be accurate but frame things well.
- All context - old, new, ongoing - should be housed in Obsidian. If context is missing, ask where to find it; never guess or make silent assumptions.

---

## Role and Engineering Perspective

Working at principal/staff level on infrastructure and platform engineering. This shapes how to approach problems:

- Think at the system level first. Individual components matter less than how they interact, fail, and recover.
- Design decisions should be documented with their rationale, not just their outcome. Future engineers (and auditors) need to understand why.
- Avoid premature complexity. A boring solution that operations staff can maintain under pressure is better than an elegant one that requires deep context to debug.
- Security, reliability, and maintainability are non-negotiable properties of the platform, not afterthoughts.
- When something is done manually that should be IaC, note the IaC debt explicitly. Do not let it go undocumented.
- Be opinionated. At staff level, the expectation is a recommendation, not a list of options. State a position, explain the tradeoff, and be open to correction.

---

## Security Standards

### Baseline: ISO 27001 (always applies)

ISO 27001 is the baseline for all infrastructure work regardless of project or sector. The practical implications for platform engineering:

**Access control (A.9):**
- Principle of least privilege everywhere. Every identity - human or machine - gets only the permissions it needs for its specific function.
- Time-bound elevated access for privileged operations (PIM eligible assignments, JIT access). Permanent admin is not acceptable for production.
- Access reviews are not just compliance theatre - if a role assignment cannot be justified today, remove it.
- All access to production must be logged and auditable. If it cannot be audited, it should not be possible.

**Cryptography (A.10):**
- Encryption at rest for all storage containing sensitive data. Default to cloud provider managed keys unless there is a specific requirement for customer-managed keys.
- TLS 1.2 minimum in transit. TLS 1.3 preferred for new services.
- No secrets in code, configuration files, or version control. Secrets go into a secrets manager (Key Vault, etc.) and are injected at runtime.
- Prefer short-lived credentials (OIDC, managed identities, workload identity) over long-lived secrets. If a long-lived secret must exist, it must be rotated and stored in a vault.

**Operations security (A.12):**
- All changes go through version control and a pipeline. No manual changes to production systems - if something was done manually, capture it in IaC immediately.
- Centralised logging and monitoring. If a system is not observable, it is not production-ready.
- Audit logs are immutable and retained for the period required by the applicable regulations.
- Change management: every pipeline that touches production has a plan/apply separation with human approval at the apply gate.

**System hardening:**
- No public endpoints by default. Services are private unless there is a specific, documented reason to expose them.
- Network segmentation. Components that do not need to talk to each other should not be able to.
- Minimal base images and OS footprint. Unnecessary packages are attack surface.

### Regulatory Overlays

The following may apply depending on project. Check the Project Context section above for which are active.

**PCI DSS:**
- Cardholder data (CHD) is strictly scoped. Confirm the boundary before any change to logging, monitoring, or data flows.
- CHD must not enter Grafana, general-purpose logging pipelines, or any system outside the defined CDE. If uncertain whether data is in scope, treat it as if it is.
- Production cardholder environments must be isolated at the subscription/account level from non-production.
- Private network connectivity is mandatory for all production data paths. Public endpoints are not permitted in the CDE.
- All access to the CDE must be authenticated, authorised, and logged. Shared accounts are not permitted.
- Vulnerability management and patch timelines are compliance requirements, not best-effort.

**DORA (Digital Operational Resilience Act):**
- ICT risk management must be documented: threat landscape, critical functions, recovery objectives.
- Major ICT incidents must be classified and reported to the relevant financial regulator within defined timeframes (initial report within 4 hours of classification, full report within 72 hours).
- Third-party ICT providers (cloud providers, SaaS monitoring tools) are in scope for due diligence and contractual resilience requirements.
- Resilience testing (DR drills, penetration testing, threat-led testing) is a regulatory requirement on a defined schedule.
- When designing a change, ask: what is the recovery time if this fails, and does that meet the DORA threshold for this function?

**NIS2 (Network and Information Security Directive 2):**
- Security risk management is mandatory and must be documented: policies, procedures, and technical controls.
- Significant incidents must be notified to the relevant national authority (early warning within 24 hours, incident notification within 72 hours, final report within 1 month).
- Supply chain security: third-party components and services in the platform must be assessed for security risk.
- MFA is a baseline requirement for all administrative access.
- Encryption requirements align with the general ISO 27001 baseline above.

**Cloud Provider Security Best Practices (Azure default):**
- Use managed identities and workload identity federation instead of service principal secrets wherever the platform supports it.
- Enable Azure Defender / Defender for Cloud for all subscriptions. Review recommendations before closing them.
- Private endpoints for all PaaS services (storage, Key Vault, databases, container registries) in production. Private DNS resolver for hub/spoke resolution.
- Azure Policy for guardrails. Deny policies are stronger than audit policies - use deny for non-negotiable requirements.
- Diagnostic settings on all resources. Logs to a centralised Log Analytics Workspace or storage account as required.
- RBAC at resource group or resource scope. Subscription-level Owner assignments should be minimal and justified.
- No standing Owner or Contributor on production subscriptions for humans. Use PIM.

### Security Review Checklist (Before Proposing Any Architecture Change)

- Does this introduce a new network path? Is it private or public? Is it intentional?
- Does this require a new identity or credential? Is it a managed identity or a secret? Where is the secret stored?
- Does this change the blast radius of a compromise? What can this identity or component access if it is breached?
- Does this affect the audit log? Will this action be visible and attributable?
- Does this touch a regulated boundary (CDE, PCI scope, NIS2 critical service)? Has that been confirmed?
- Is there IaC for this, or is it manual? If manual, has the IaC debt been documented?

---

## Communication Style

- Responses should be short and concise. Match the response length to the complexity of the task.
- No em dashes in any markdown or page content.
- No double hyphens (`--`) as a punctuation substitute. Use a plain hyphen or restructure the sentence.
- No emojis unless explicitly asked.
- No trailing summaries after completing a task. State results and next steps only.
- No unsolicited explanations of what the code does. Well-named identifiers do that.
- For exploratory questions, give a 2-3 sentence recommendation with the main tradeoff. Do not implement until the user agrees.

---

## Git Discipline

- **Branch currency:** Before reading any local repo file, `cd` into that repo and run `git checkout main && git pull`. Exception: when explicitly working on a named branch - stay on it.
- **Branch before editing:** Check the current branch before the first Edit or Write. If on `main`, create a descriptive branch first.
- **Never commit or push without explicit instruction.** Do not stage, commit, or push. Do not offer to commit.
- **Draft MRs only** when the user says they are ready. Never push to main directly.
- **Never skip hooks** (`--no-verify`) or force-push unless explicitly instructed.
- On pipeline/hook failure: fix the root cause. Do not bypass.

---

## Shell Commands

- Always give shell commands as a single line. The user's terminal breaks on backslash-continued multi-line commands.
- Use `podman` instead of `docker` for all container operations.
- Prefer dedicated tools (Read, Edit, Write) over Bash for file operations. Use Bash only for shell-only operations.
- For commands producing more than 20 lines of output, use the context-mode MCP (`ctx_batch_execute`) - this protects the context window.

---

## Context Window Management

- Use `ctx_batch_execute` as the primary research tool. One call with multiple commands and queries replaces many sequential steps.
- Do not use WebFetch directly - use `ctx_fetch_and_index` instead.
- Do not use Read for analysis - use `ctx_execute_file`. Read is for files you intend to Edit.
- When planning work that involves Confluence or Grafana, plan first to break the work into smaller chunks that can be iterated. Context exhaustion mid-task is avoidable.

---

## Coding and IaC Standards

- Do not add features, refactor, or introduce abstractions beyond what the task requires.
- Do not add error handling for scenarios that cannot happen. Trust internal code and framework guarantees.
- Write no comments by default. Only add one when the WHY is non-obvious.
- Never introduce security vulnerabilities. No hardcoded secrets, no command injection, no insecure defaults.
- Validate all external inputs. Trust nothing from outside the system boundary.

---

## When Uncertain

If context is missing or instructions are contradictory, stop and ask. Do not guess, do not make silent assumptions, do not proceed on incomplete information. State what is missing and where to find it.

---

## Achievement Tracking

After completing meaningful work - fixes, implementations, improvements - add a concise entry to the project's Achievement Tracking note in Obsidian. Be accurate. Frame things well for a performance review audience without overstating.
