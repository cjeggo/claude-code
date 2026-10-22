# claude-code

A personal engineering platform built on Claude Code. Provides a shared Obsidian knowledge vault, a pre-configured CLAUDE.md, and a consistent set of skills and subagents across every project. The goal is for Claude to arrive at each session with full context and operate as a peer engineer — not a blank-slate assistant that needs briefing from scratch each time.

Clone once per machine. Run `/project-init` to configure a new project.

This is a living repo, as I discover new things I add them such as rule gaps and new agents/skills

---

## Start Here (read this first if you're rusty or this is a new machine)

**Why before how:** the actual idea here is small - a persistent external knowledge store, plus discipline (plan → design → execute → close) baked into tooling instead of left to memory. Everything else in this repo is one specific implementation of that idea, currently built on Obsidian. If you've forgotten everything else, keep that one sentence and the rest will make sense as you read it.

**Read order for a cold start:**
1. This section, then "How This Works" below - the model, not the mechanics.
2. "One-Time Machine Setup" and "New Project Setup" - get running.
3. Skim the "Subagents" and "Skills Reference" tables - know what exists, don't memorize it.
4. Everything else is reference - come back to it when something needs it, don't read it all up front.

**Coming back after real time away?** See "Returning After Time Away" further down before you assume anything here still matches reality - plugin versions, hook installation, and vault state all drift while you're gone.

**Not using Obsidian anymore?** See "The Obsidian Dependency" further down - this is a real, structural coupling, not just a config setting, and the honest answer is not "swap the tool name."

---

## How This Works

The scaffold enforces a deliberate collaboration model. Every project runs the same pattern.

**Plan before building.** Non-trivial work starts with a written plan, saved to `Plans/` in the vault. Plans include goals, constraints, implementation steps, and open questions. Claude proposes; the engineer approves. This keeps changes auditable and prevents scope drift.

**Design, then execute.** For complex changes — new infrastructure, PCI-adjacent work, security decisions — there is a design phase before any implementation. Specialised skills enforce this: the PCI compliance skill must run before any change touching the CDE boundary; the Azure Enterprise Infra Planner skill structures infrastructure decisions; the terraform-preflight agent validates before any branch is marked ready. Subagents isolate expensive work (research, preflight checks, impact assessments) from the main conversation so context stays clean throughout a session.

**Session close.** "Wrap up" triggers the `session-close` agent. It writes an outcome-led achievement entry (not a task list) to Obsidian and routes carry-overs to harness memory - not a vault session summary note, which was retired as legacy/unused. The next session starts where this one left off via memory + the Achievement Tracking note.

**Accumulating knowledge.** The Obsidian vault is the shared brain. Each session adds to it. Plans reference prior decisions. Workstream notes track state across sessions. Over time Claude's understanding of the project deepens rather than resetting — architectural decisions, compliance constraints, team context, and prior investigation results are all available from the start of every session.

This is what separates the setup from ad-hoc Claude usage: the discipline is baked into the tooling, not left to the engineer to enforce each session.

---

## Structure

```
claude-code/
  hooks/                         <- installed to ~/.claude/hooks/ by /project-init
  skills/                        <- symlinked to ~/.claude/skills/ by /project-init
    project-init/                <- first-session configuration wizard (/project-init)
    pci-compliance/
    azure-enterprise-infra-planner/
    azure-kubernetes/
    terraform-engineer/
    kubernetes-specialist/
    gitlab-ci-patterns/
    monitoring-expert/
    sre-engineer/
    devops-engineer/
    vault-propagate/
    stop-slop/                    <- strip AI writing tells before external-facing artifacts
    task-observer/                <- meta-skill: spot new-skill candidates (narrow scope per-project if a correction-capture mechanism already exists)
    vault-memory-hygiene/          <- on-demand: orphaned/broken memory links, unarchived closed plans, one-directional backlinks
    terraform-private-endpoint-import/  <- import a VNet-only resource via the MR pipeline's network-connected runner
    azure-hub-firewall-diagnostics/     <- diagnose silent outbound HTTPS failures from a spoke subnet (hub firewall IP-Group checklist)
    aks-bastion-live-access/            <- live kubectl access to a private AKS cluster via az aks bastion tunnel
    ci-rbac-gap/                        <- CI job Azure 403/401: identity forensics + role-assignment-as-code fix
    terraform-state-account-private-only/ <- make a Terraform state-backend storage account private-endpoint-only without breaking consumers
    defender-finding-triage/            <- triage Defender for Cloud recommendations: false positive, deliberate exception, or real fix
    grafana-alert-noise-audit/          <- measure and cut Grafana alert noise from alert state history, replay scoping, verify
    obsidian-index-maintenance/         <- keep an _index.md in every vault folder so notes are found by navigating indexes
    vap-live-verification/              <- prove a ValidatingAdmissionPolicy denies on a live AKS cluster: Fail scratch copy, dry-run requests, propagation check
  agents/                        <- copied to .claude/agents/ by /project-init
    session-close.md             <- achievement tracking + carry-overs to harness memory on "wrap up"
    terraform-preflight.md       <- fmt/validate/docs/lock checks before review
    pci-impact.md                <- PCI DSS v4.0 impact assessment
    ci-infra-investigator.md     <- diagnose a hung or killed GitLab CI pipeline: job forensics against runner metrics
  vault-template/                <- deployed to Obsidian vault by /project-init
    Claude/
      CLAUDE-template.md         <- tools and MCP reference
      Tools & MCPs.md            <- tools and MCP reference
    Project/                     <- renamed to project name during deploy
      Workstreams/
      Reference/
      Archive/
      Achievement Tracking.md    <- written by session-close agent, outcome-led
    Shared/                      <- cross-project knowledge at vault root
      Technical Reference/       <- platform standards and reference material
      Decisions/                 <- architectural decisions that set cross-project precedent
      Patterns/                  <- reusable patterns validated in at least one project
  CLAUDE.md                      <- template, copied to project root by /project-init
  settings.local.json.template   <- template, becomes .claude/settings.local.json by /project-init
  README.md
  .gitignore
```

---

## One-Time Machine Setup

Do this once when setting up a new machine.

```shell
git clone git@github.com:<your-user>/claude-code.git ~/repo/claude-code
```

That is it. The first time you run `/project-init` on any project it will create the global skills symlink (`~/.claude/skills` → `<scaffold-path>/skills`) and install the SessionStart gate hook if either is missing.

---

## New Project Setup

Open Claude Code in the project directory and run:

```
/project-init
```

The wizard asks for the scaffold repo path first (default `~/repo/claude-code`), then handles everything else automatically:

- Copies CLAUDE.md, agents, and settings template from the scaffold repo into the project
- Creates `.claude/agents/`, `.claude/skills/`, `.claude/settings.local.json`
- Creates the global `~/.claude/skills` symlink and installs hooks if not already present
- Interviews you on project identity, tech stack, regulatory context, tools, vault root, and project subfolder
- Deploys `vault-template/Project/` to your project subfolder in Obsidian, and `vault-template/Shared/` to the vault root (once, idempotent)
- Trims agents and skills to what is relevant for this project
- Fills in every placeholder in CLAUDE.md, including vault root and project folder paths

Run it once. Re-run it if the project scope changes significantly.

### Vault model

Each project gets a subfolder within a single shared Obsidian vault. The vault root is the shared brain - cross-project knowledge, patterns, and architectural decisions live in `Shared/` at the root. Project-specific notes (workstreams, plans, reference material) live in the project subfolder. Claude has access to the entire vault from the start of every session.

After any ingest operation, run `/vault-propagate` to push new context through all related vault pages vault-wide. This is the step that turns isolated notes into a connected knowledge graph.

### The Obsidian Dependency

Be honest with yourself about this one: **this is not a config setting, it's a structural coupling.** The underlying idea (a persistent external knowledge store, discipline baked into tooling) doesn't require Obsidian specifically - but the actual implementation here does, in these concrete places:

- `session-close` agent hardcodes `mcp__obsidian-vault__*` tools - it doesn't run at all without them.
- `vault-propagate` and `vault-memory-hygiene` are Obsidian-specific by name and by mechanism (wikilinks, vault folder structure).
- The CLAUDE.md template has a section literally titled "Obsidian as the Shared Brain."
- `project-init`'s only answer to "I don't have a vault" is "go set one up" - there is no supported path for a different tool.

If you ever actually switch (Notion, plain markdown, anything else), this is a real migration, not a find-and-replace: the agents' tool lists need different MCP tools (or a different mechanism entirely if the target tool has no MCP server), `vault-propagate`/`vault-memory-hygiene` need re-implementing against the new tool's structure, and the CLAUDE.md template's vault section needs rewriting, not renaming. Don't assume "swap the word Obsidian for Notion" gets you there - budget it as a real piece of work, and do it deliberately rather than piecemeal once you notice something's broken.

---

## Plugins

Plugins extend Claude Code with additional MCP servers and skills. They are installed at user scope (`~/.claude/plugins/`) and are available across all projects. The plugin cache is auto-managed and should not be committed to git.

**To install a plugin:** Type `/plugin` in Claude Code, search for the plugin name, and select it. Then run `/reload-plugins` to apply.

**To update a plugin:** Type `/plugin` again - installed plugins show an update option if a newer version is available. Some plugins expose their own upgrade skill (e.g. `/ctx-upgrade` for context-mode).

**To check what is installed:** `cat ~/.claude/plugins/installed_plugins.json`

### Installed Plugins

Versions below are a snapshot from whenever this table was last updated, not a live source - check `~/.claude/plugins/installed_plugins.json` for what's actually installed, especially after time away.

| Plugin | Slug | Source | Version | What it provides |
|--------|------|--------|---------|-----------------|
| context-mode | `context-mode@context-mode` | github: `mksglu/context-mode` | 1.0.151 | Context window protection MCP - runs commands and indexes output into a local FTS5 store; returns search results rather than raw output. Use `ctx_batch_execute` instead of Bash for any command producing more than ~20 lines. |
| superpowers | `superpowers@claude-plugins-official` | github: `anthropics/claude-plugins-official` | 5.1.0 | Workflow meta-skills - structured plans, TDD, parallel agents, debugging, branch close-out. All invoked via `/superpowers:<skill-name>`. |
| context7 | `context7@claude-plugins-official` | github: `anthropics/claude-plugins-official` | - | Library documentation MCP - fetches current docs for any framework or SDK directly from source. Use before debugging library-specific errors or checking current API syntax. |
| claude-obsidian | `claude-obsidian@claude-obsidian-marketplace` | github: `AgriciDaniel/claude-obsidian` | 1.6.0 | Full Obsidian wiki workflow - ingest, lint, query, save, canvas. Invoked via `/claude-obsidian:<skill-name>`. |
| obsidian | `obsidian@obsidian-skills` | github: `kepano/obsidian-skills` | 1.0.1 | Obsidian format and syntax skills - markdown, canvas JSON, CLI, bases. Invoked via `/obsidian:<skill-name>`. |
| ponytail | `ponytail@ponytail` | github: `DietrichGebert/ponytail` | 4.8.3 | YAGNI enforcement and over-engineering review. Three modes: `/ponytail lite` (build it, name the lazier option), `/ponytail` (full ladder: YAGNI → stdlib → native → minimum), `/ponytail ultra` (deletion before addition, challenges requirements). |

### Key Plugin Skills

| Skill | Plugin | When to use |
|-------|--------|-------------|
| `/context-mode:context-mode` | context-mode | Full instructions and usage guide |
| `/context-mode:ctx-upgrade` | context-mode | Upgrade to latest version |
| `/context-mode:ctx-purge` | context-mode | Wipe knowledge base (irreversible) |
| `/superpowers:writing-plans` | superpowers | Write a structured implementation plan |
| `/superpowers:subagent-driven-development` | superpowers | Execute a plan via fresh subagent per task with two-stage review |
| `/superpowers:systematic-debugging` | superpowers | Structured debugging workflow |
| `/superpowers:finishing-a-development-branch` | superpowers | Branch close-out checklist |
| `/claude-obsidian:wiki-ingest` | claude-obsidian | Batch ingest multiple sources into vault |
| `/claude-obsidian:wiki-lint` | claude-obsidian | Full vault health check |
| `/claude-obsidian:wiki-query` | claude-obsidian | Synthesise answers from across vault |
| `/ponytail` | ponytail | Activate YAGNI mode (full by default) |
| `/ponytail-review` | ponytail | Over-engineering review of current code |
| `/ponytail-gain` | ponytail | Measured-impact scoreboard: less code, less cost, more speed |

### Notes

- Plugins are **not project-specific** - they are installed at user scope and available everywhere.
- The plugin cache at `~/.claude/plugins/cache/` is rebuilt automatically on install/update. Do not commit it.
- context-mode is the highest-value plugin for large infrastructure projects where commands produce voluminous output. Enable it early.

---

## Local Model Delegation (Ollama)

Optional, off by default. Offloads cheap read-only lookups (vault search, ticket search, pipeline polling) to a local model instead of spending Claude tokens on them, and gives a path to keep genuinely sensitive workstreams (e.g. security recon/fuzzing) fully local with no cloud LLM involved at all. Not part of the core scaffold model above - a separate, additive layer.

### Setup

1. Install Ollama: `brew install ollama` (macOS) - see ollama.com for other platforms.
2. Start the server: `ollama serve`. Claude Code can be granted standing permission to do this itself (see "Standing permission" below) rather than asking each session.
3. Pull a model: `ollama pull qwen3:8b` (~5.2GB, hybrid thinking/non-thinking, decent tool-calling reliability at 8B on typical dev hardware - bump to a larger variant if reasoning depth or tool-call reliability becomes the bottleneck).
4. Verify: `curl http://localhost:11434/api/tags` should list the pulled model.

### Two delegation patterns

**1. Direct pipe, local files only.** `find`/`grep`/`cat` piped straight into `ollama run <model> --hidethinking "<question>"` - one shell call, no intermediate write to a scratch file (writing first just re-spends the tokens you were trying to save). Used for vault lookups and other local file search.

Critical: always pass `--hidethinking` (or `think:false` via the API). Without it the full reasoning trace streams back into Claude's context - on an 8B thinking model this is routinely several times larger than the source content, a net loss versus reading the file directly.

**2. Native tool-calling agent, API-backed sources (Jira, GitLab, etc).** A small Python script per external system, driving Ollama's `/api/chat` endpoint with a tool-calling loop - not OpenCode (its arbiter/routing layer added 40s+ of unexplained latency in testing and was abandoned; raw Ollama tool-calling was never the problem). Every such script needs, non-negotiably:

- Iteration cap (total round-trips to the model)
- Per-source call cap, independent of iteration count
- Dedup on repeated/identical queries (the actual "hammering an API" failure mode - a confused model retrying the same call hoping for a different answer)
- Per-call timeout and an overall wall-clock cap, checked every iteration
- Read-only tools only - no create/update/delete tool defined, ever. This should be structural (the tool doesn't exist), not a permission flag that could be bypassed
- Every call logged to stderr for auditability

These scripts are project-adjacent tooling, not Claude Code config - they live in a separate plain directory (not this repo), one per machine/setup, since they hold real API credentials and are invoked directly, not through the scaffold's skill/agent mechanism.

### Enforcement: hooks, not memory

Telling Claude "use the local model for X" in CLAUDE.md or a skill does not reliably work - it still falls back to calling the MCP tool directly under normal conversational pressure. The pattern that actually holds is a `PreToolUse` hook that:

- Health-checks the local Ollama endpoint
- If reachable: `deny`s the direct MCP tool call with a reason string telling Claude exactly which script to run instead
- If unreachable: returns `ask` (a real permission prompt), not a silent bypass - Claude gets a chance to start Ollama itself and retry first, and only falls through to the direct MCP call with explicit per-instance approval

This is the only mechanism in this repo that structurally enforces a routing preference rather than hoping Claude remembers it.

### How to switch it off

- **Per source:** remove the matching entry from `hooks.PreToolUse` in the project's `.claude/settings.json`, and delete/rename the matching guard script in `.claude/hooks/`. The MCP tool goes back to working directly - no restart needed.
- **Everywhere on this machine:** `ollama stop <model>` unloads a running model from memory. `ollama rm <model>` reclaims disk. `brew uninstall ollama` removes it entirely.
- **Standing permission:** if a project's CLAUDE.md grants Claude standing permission to run `ollama serve`/`ollama pull`/`ollama run` without asking, that line is an explicit grant, not a scaffold default - remove it from that project's CLAUDE.md to revoke it.

---

## Subagents

Agents in `agents/` are subagents that run with their own context window, keeping raw tool output out of the main conversation. They are invoked on request or triggered by named phrases.

| Agent | When it runs | What it does |
|-------|-------------|--------------|
| `session-close` | When user says "wrap up" | Writes an achievement tracking entry and routes carry-overs to harness memory. Claude drafts the brief; agent handles all Obsidian mechanics. |
| `terraform-preflight` | Before marking a Terraform branch ready for review | Runs fmt, validate, terraform-docs, and lock file checks. Returns a pass/fail checklist. |
| `pci-impact` | Before implementing any change near the CDE boundary | Assesses the change against PCI DSS v4.0 requirements. Returns an in-scope determination and required actions. |

### Generic vs project-specific agents

The versions in `agents/` are generic templates. `/project-init` copies them to `.claude/agents/` and hardens them with project-specific values (vault path, Jira project keys, etc.) during setup. The copies in `.claude/agents/` are what actually run - edit those for further project-specific changes, then sync back to the scaffold repo.

### Retired: SessionStart briefing

An earlier version of this scaffold ran a `session-start` agent automatically via a `SessionStart` hook (`session-start-gate.sh`), gated to skip on `/clear` mid-session. It was retired: the agent's own frontmatter description ("invoke before any other work begins") kept resurfacing in the agent listing shown every session and overrode the gating logic, causing unsolicited briefings even when a project's memory explicitly said not to run it. Obsidian search on demand replaced it — pull context when a task needs it, not proactively on every session start. If you find `session-start-gate.sh` still referenced in `~/.claude/settings.json` or a project's `settings.local.json`, remove the hook entry and delete `~/.claude/hooks/session-start-gate.sh`.

To invoke an agent manually, just ask: "run terraform-preflight on `/path/to/repo`" or "run pci-impact on this change".

### Adding a new agent

New agents are typically identified during project work - a pattern repeats, a workflow benefits from context isolation. Create the agent where you are:

```shell
# In the project directory
touch .claude/agents/<agent-name>.md
```

Frontmatter format:

```yaml
---
name: agent-name
description: "When to invoke this agent - used by the model for routing decisions"
tools: [Tool1, Tool2]   # optional - omit to allow all tools
---
```

Then write the agent's system prompt as the body. Agents should be self-contained: include all context they need without relying on the parent conversation.

Once tested, sync back to the scaffold so it is available to future projects:

```shell
cp .claude/agents/<agent-name>.md ~/repo/claude-code/agents/
cd ~/repo/claude-code && git add agents/<agent-name>.md && git commit -m "add <agent-name> agent" && git push
```

---

## Maintaining Skills

Skills live in `~/repo/claude-code/skills/` and are symlinked to `~/.claude/skills/`, so edits are live immediately across all projects on this machine.

**To update an existing skill:**

Edit directly in the scaffold repo - changes are live immediately via the symlink:

```shell
# Edit in place
~/repo/claude-code/skills/<skill-name>/SKILL.md

# Then commit and push
cd ~/repo/claude-code && git add skills/<skill-name>/ && git commit -m "update <skill-name>: <what changed and why>" && git push
```

**To add a new skill:**

New skills are usually identified during project work. The `/project-init` gap detection can scaffold a stub automatically. Otherwise, create it where you are working and sync back:

```shell
# Create in the project first
mkdir -p .claude/skills/<skill-name>
# ... write SKILL.md ...

# Test it in the session, then sync back to scaffold
cp -r .claude/skills/<skill-name>/ ~/repo/claude-code/skills/<skill-name>/
cd ~/repo/claude-code && git add skills/<skill-name>/ && git commit -m "add <skill-name> skill" && git push
```

Minimum required frontmatter:

```yaml
---
name: your-skill-name
description: "One sentence. Describe what the skill does and list trigger phrases."
allowed-tools: Read Write Edit Bash
---
```

**To pull updates on a new machine:**

```shell
cd ~/repo/claude-code && git pull
```

The symlink means updates are live immediately without re-linking.

---

## Returning After Time Away

Nothing in this repo actively rots, but the things around it do - plugins update independently, hooks can silently stop being installed, and the vault accumulates unarchived drift the whole time you're not looking at it. Before trusting anything below at face value after a real gap (weeks, months, a machine change):

1. **Pull the scaffold.** `cd ~/repo/claude-code && git pull` - the skills symlink means this is live immediately, no re-linking needed.
2. **Check plugin versions.** `cat ~/.claude/plugins/installed_plugins.json` and compare against the "Installed Plugins" table below - the table is a snapshot from whenever it was last updated, not a live source. Run `/plugin` to check for and apply updates.
3. **Verify hooks are still installed.** The SessionStart gate and the graphify hook-guard (if a project uses graphify) both live outside this repo, in `~/.claude/hooks/` and project `.claude/settings.json` - a machine change or a Claude Code upgrade can lose these silently. Run `/hooks` to check.
4. **Run `/vault-memory-hygiene`** on any project you're returning to - it finds exactly the kind of drift that accumulates unattended: orphaned/broken memory links, plans never archived, one-directional backlinks.
5. **Re-read "Start Here" above** before assuming any specific mechanic (an agent's exact tool list, a plugin's exact skill names) still matches what's installed - this file describes intent; the installed state is the source of truth.

---

## What Not to Commit

The `.gitignore` covers these but worth being explicit:

- `~/.claude/projects/` - per-project memory files; may contain sensitive session context
- `~/.claude/plugins/` - auto-managed plugin cache, rebuilt automatically
- `*.local.json` - machine-specific settings
- `.obsidian/` - Obsidian app config, machine-specific

---

## Skills Reference

| Skill | Command | Purpose |
|-------|---------|---------|
| Project Init | `/project-init` | First-session setup wizard |
| PCI Compliance | `/pci-compliance` | Required before any PCI-impacting change |
| Azure Enterprise Infra Planner | `/azure-enterprise-infra-planner` | Plan Azure infrastructure |
| Azure Kubernetes | `/azure-kubernetes` | AKS cluster design and best practices |
| Terraform Engineer | `/terraform-engineer` | Terraform IaC: modules, state, import |
| Kubernetes Specialist | `/kubernetes-specialist` | Workloads, RBAC, ArgoCD, GitOps, Helm |
| GitLab CI Patterns | `/gitlab-ci-patterns` | GitLab CI/CD pipeline patterns |
| Monitoring Expert | `/monitoring-expert` | Prometheus, SLOs, structured logging, Grafana |
| SRE Engineer | `/sre-engineer` | SLOs, error budgets, toil automation |
| DevOps Engineer | `/devops-engineer` | CI/CD pipelines, container builds |
| Vault Propagate | `/vault-propagate` | Post-ingest: push new context vault-wide through all related pages |
| Stop Slop | `/stop-slop` | Strip AI writing tells from prose. Required before finalizing any external-facing artifact |
| Task Observer | `/task-observer` | Meta-skill: spot new-skill candidates from recurring manual patterns. Narrow scope per-project if a correction-capture mechanism already exists (see the skill's own scope note) |
| Vault & Memory Hygiene | `/vault-memory-hygiene` | On-demand periodic check: orphaned/broken memory links, unarchived closed plans, one-directional vault backlinks |
| Terraform Private Endpoint Import | `/terraform-private-endpoint-import` | Import a VNet-only resource via the MR pipeline's network-connected runner |
| Azure Hub Firewall Diagnostics | `/azure-hub-firewall-diagnostics` | Diagnose silent outbound HTTPS failures from a spoke subnet (hub firewall IP-Group checklist) |
| AKS Bastion Live Access | `/aks-bastion-live-access` | Live kubectl access to a private AKS cluster via `az aks bastion` backgrounded tunnel + device-code sign-in |
| CI RBAC Gap | `/ci-rbac-gap` | CI job fails with an Azure 403/401/RoleAssignmentExists - identity forensics, role-assignment-as-code change, manual-grant collision handling |
| Terraform State Account Private-Only | `/terraform-state-account-private-only` | Make a state-backend storage account private-endpoint-only without breaking consumers |
| VAP Live Verification | `/vap-live-verification` | Prove a ValidatingAdmissionPolicy denies on a live AKS cluster: scratch copy with failurePolicy Fail, server-side dry-run requests, parameter-not-found exposure, edit-propagation check, cleanup by recorded PID. |

---

## Regulatory Standards Covered by Skills

| Skill | Standard |
|-------|----------|
| `/pci-compliance` | PCI DSS v4.x |
| All skills | ISO 27001 baseline baked into CLAUDE.md |
| CLAUDE.md template | DORA, NIS2 overlays documented |

Update `/pci-compliance` when PCI DSS publishes new requirements. The skill is owned here - no dependency on an upstream maintainer.
