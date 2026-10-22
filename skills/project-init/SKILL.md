---
name: project-init
description: First-session project configuration wizard. Interviews the user to configure CLAUDE.md, settings.local.json, and the .claude/agents/ copies for a new project. Run once at the start of a new engagement. Triggers on /project-init.
allowed-tools: Read, Write, Edit, Bash
---

# Project Init

You are configuring a new Claude Code project. Your job is to interview the user, then make concrete edits to `CLAUDE.md`, `settings.local.json`, and the agent files in `.claude/agents/` so the project is fully configured before any real work begins.

Do not rush. Ask one group of questions at a time and wait for answers before proceeding. Confirm what you are about to edit before writing. Leave nothing as a template placeholder when you are done.

---

## Pre-step - Scaffold path

Check whether `~/repo/claude-code` exists:

```shell
ls ~/repo/claude-code/CLAUDE.md 2>/dev/null && echo "found" || echo "not found"
```

- If found: set `SCAFFOLD=~/repo/claude-code` and proceed silently. Do not ask the user.
- If not found: ask the user to provide the path to the claude-code scaffold repo before continuing. Do not proceed without it.

Store the confirmed path as `SCAFFOLD` for use throughout the rest of the skill.

---

## Step 0 - Setup and cleanup

Detect which state the project is in and act accordingly. Report everything that is moved or created.

### Detect state

Three possible states:

1. **Fresh project** - no `CLAUDE.md`, no `.claude/` directory, no scaffold files in root. Nothing has been copied yet.
2. **Manual scaffold copy** - scaffold files present at project root (`agents/`, `skills/`, `vault-template/`, `settings.local.json.template`, `README.md`). User copied the repo in the old way.
3. **Already configured** - `CLAUDE.md` is present and not a template, `.claude/agents/` exists. Skip to step 0b.

---

### If fresh project - copy from scaffold

```shell
mkdir -p .claude/agents .claude/skills
cp "$SCAFFOLD/CLAUDE.md" ./CLAUDE.md
cp "$SCAFFOLD/agents/"*.md .claude/agents/
sed "s|{{HOME}}|$HOME|g" "$SCAFFOLD/settings.local.json.template" > .claude/settings.local.json
```

Leave `vault-template/` in the scaffold repo - it will be deployed to Obsidian in step 9 once the vault path is known.

---

### If manual scaffold copy - clean up in place

```shell
mkdir -p .claude/agents .claude/skills
```

**Move agents:**
```shell
mv agents/*.md .claude/agents/ && rmdir agents/
```

**Handle skills** - the global symlink provides all standard skills; a root-level copy is just stale duplicates:
- If `skills/` contains only standard scaffold skills, delete it: `rm -rf skills/`
- If `skills/` contains any non-standard directories, move those to `.claude/skills/` first, then delete the rest

**Move settings template:**
```shell
sed "s|{{HOME}}|$HOME|g" settings.local.json.template > .claude/settings.local.json && rm settings.local.json.template
```
If `.claude/settings.local.json` already exists, just remove the template without overwriting.

**Install and remove hooks:**
```shell
mkdir -p ~/.claude/hooks
for f in hooks/*; do
  target="$HOME/.claude/hooks/$(basename $f)"
  [ ! -f "$target" ] && cp "$f" "$target" && chmod +x "$target"
done
rm -rf hooks/
```
Non-destructive: only copies a hook if the target does not already exist.

**Remove scaffold README** - only if it contains scaffold content (check first line for "Personal Claude Code scaffold"):
```shell
rm README.md
```

**vault-template/** - leave in place; will be deployed in step 9.

---

### Both states - global skills symlink and hooks

After either path above, check and fix the global symlink and hooks:

```shell
[ ! -e ~/.claude/skills ] && ln -s "$SCAFFOLD/skills" ~/.claude/skills
mkdir -p ~/.claude/hooks
for f in "$SCAFFOLD/hooks/"*; do
  target="$HOME/.claude/hooks/$(basename $f)"
  [ ! -f "$target" ] && cp "$f" "$target" && chmod +x "$target"
done
```

---

## Step 0b - Read current state

After cleanup, read the following files so you know what is already filled in and what is still template:

- `CLAUDE.md` in the project root
- `.claude/settings.local.json`
- Every file in `.claude/agents/`

Note which CLAUDE.md sections are still template placeholders (`_fill in_`, `_Describe...`, etc.) and which are already populated. If everything is already filled in, tell the user and ask what they want to change.

---

## Step 1 - Project identity

Ask (all at once, as a numbered list):

1. What is the project name?
2. One or two sentences: what is this project? (product, system, domain)
3. What is the local directory structure? How does it map to remote repos? (Paste a tree or describe it - you just need enough to fill in the Repository / Directory Structure section.)
4. Key technologies: cloud provider, IaC tooling, CI/CD platform, languages/runtimes, Kubernetes? List them.

End with: "**Reply with your answers and I will move to the next section.**"

Do not proceed to step 2 until you have all four answers.

---

## Step 2 - Regulatory context

Ask:

1. Is PCI DSS in scope for this project? (yes / no / uncertain)
2. Does DORA apply? (yes if the organisation is a financial entity under EU regulation)
3. Does NIS2 apply?
4. Any other standards: SOC 2, HIPAA, ISO 27001 (already baseline), other?

If the user is uncertain about any of these, note it explicitly in CLAUDE.md as "Uncertain - confirm before any compliance-sensitive change." Do not leave it blank.

End with: "**Reply with your answers and I will move to the next section.**"

---

## Step 3 - Source control and CI/CD

Ask:

1. Git platform: GitLab / GitHub / other?
2. Are there any group, org, or repo access restrictions I should know about? (e.g. "only query repos under my-org/my-team/iac")
3. Is there a CI/CD pipeline pattern I should be aware of? (e.g. "all deployment is through GitLab CI, no local apply")

End with: "**Reply with your answers and I will move to the next section.**"

---

## Step 4 - External tools and MCPs

Ask (present as a checklist - user can answer yes/no or skip):

Which of the following are available and in use on this project?

- [ ] Jira - if yes, which project keys?
- [ ] Confluence - if yes, which space(s)?
- [ ] GitLab MCP
- [ ] GitHub MCP
- [ ] Grafana - if yes, what is the instance URL?
- [ ] Azure CLI (`az`)
- [ ] Any other MCPs or external tools?

End with: "**Reply with your answers and I will move to the next section.**"

---

## Step 5 - Obsidian vault

Ask:

1. What is the absolute path to the Obsidian vault root? (e.g. `/Users/name/Documents/Obsidian/MyVault` - the top-level vault directory, not a project subfolder)
2. What is the project folder path within the vault? (e.g. `Work/my-project` or `Side-Projects/my-idea`)

If the user says no Obsidian vault yet, note that the session-start and session-close agents will not function until one is set up and prompt them to run `/claude-obsidian:wiki` to scaffold it.

End with: "**Reply with your answers and I will move to the next section.**"

---

## Step 6 - Agents

Based on the answers so far, build a proposed agent keep list and present it clearly:

```
Proposed agents for this project:

  Keep:
    - session-start   (always included - reads vault on demand)
    - session-close   (always included - writes vault summary)
    - terraform-preflight   [only if Terraform confirmed in step 1]
    - pci-impact            [only if PCI DSS confirmed in scope in step 2]

  Remove:
    - [list any agents not included above, with one-line reason]
```

Then ask two explicit questions:

1. "Does this agent list look right, or do you want to add or remove anything? Reply to confirm or change it."
2. "Are there any recurring workflows in this project - repeated multi-step sequences you find yourself doing - that might benefit from a dedicated agent? If so, describe the pattern and I will propose one."

Do not proceed to step 7 until the user has replied to both questions.

---

## Step 7 - Skills

Based on the tech stack confirmed in step 1, build a keep/remove/gap list. Do not present all skills as options - make a decision for each one and explain it. Only ask the user to confirm the keep list and any flagged gaps.

### Decision table

Work through every available skill:

**`/azure-enterprise-infra-planner`**
- Keep if: Azure is the cloud provider
- Remove if: AWS, GCP, or no cloud infrastructure work

**`/azure-kubernetes`**
- Keep if: Azure + Kubernetes (AKS)
- Remove if: non-Azure k8s, or no Kubernetes at all

**`/terraform-engineer`**
- Keep if: Terraform is the IaC tooling
- Remove if: Pulumi, CDK, Bicep only, or no IaC

**`/kubernetes-specialist`**
- Keep if: Kubernetes is in the stack (any cloud or on-prem)
- Remove if: no Kubernetes

**`/gitlab-ci-patterns`**
- Keep if: GitLab CI is the CI/CD platform
- Remove if: GitHub Actions, Jenkins, Azure DevOps only

**`/monitoring-expert`**
- Keep if: observability is in scope (Prometheus, Grafana, Loki, any metrics/alerting work)
- Remove if: no observability work planned

**`/sre-engineer`**
- Keep if: SLOs, reliability engineering, or incident management are in scope
- Remove if: pure infra provisioning project with no operational focus

**`/devops-engineer`**
- Keep if: CI/CD pipelines, container builds, or deployment automation are in scope
- Remove if: already covered by a more specific skill and not needed separately

**`/pci-compliance`**
- Keep (and mark Required) if: PCI DSS is in scope
- Remove if: PCI confirmed not in scope

### Gap detection

After building the keep list, check for gaps: technologies confirmed in step 1 that no existing skill covers well. Common examples:

- AWS infrastructure → no `/aws-infra-planner` exists
- GitHub Actions → no `/github-actions-patterns` exists
- Pulumi or CDK → no `/pulumi-engineer` or `/cdk-engineer` exists
- Bicep/ARM → no `/bicep-engineer` exists
- Specific language runtime (Go, Java, Python services) → no language-specific skill

For each gap, flag it explicitly:

```
Gap: [technology] - no skill exists for this. Options:
  a) Build a new skill now (I will scaffold it in skills/<name>/)
  b) Note it in CLAUDE.md as an area without skill coverage and handle inline
  c) Skip - not significant enough to warrant a skill
```

Ask the user which option they want for each gap before proceeding.

If the user chooses option (a), scaffold the skill file at `.claude/skills/<name>/SKILL.md` with:
- Correct frontmatter (name, description, allowed-tools)
- A placeholder body: "# [Skill Name]\n\n> Scaffold created by /project-init. Fill in the skill body before use."
- A note in CLAUDE.md that this skill is a stub and needs authoring

Note to the user: once the stub is authored and tested, sync it back to the scaffold repo:
```shell
cp -r .claude/skills/<name>/ <scaffold-path>/skills/<name>/
cd <scaffold-path> && git add skills/<name>/ && git commit -m "add <name> skill" && git push
```

### Present for confirmation

Show the final list:

```
Skills to keep:
  - /skill-name - reason

Skills to remove (not relevant to this stack):
  - /skill-name - reason

Gaps flagged:
  - [technology]: [chosen option]
```

Ask: "Does this look right?"

---

## Step 8 - Confirm before writing

Before making any edits, present a one-page summary of what you are about to change:

```
Structural cleanup (already done in step 0 - listed for reference)
  - agents/ → .claude/agents/
  - skills/ → removed (covered by global symlink)
  - settings.local.json.template → .claude/settings.local.json
  - hooks/, README.md → removed

vault-template/ → [vault root]/[project folder]/
  - vault-template/Project/ → [vault root]/[project folder]/
  - vault-template/Claude/ → [vault root]/Claude/ (if not already present)
  - vault-template/Shared/Technical Reference/ → [vault root]/Shared/Technical Reference/ (if not already present)
  - vault-template/Shared/Decisions/ → [vault root]/Shared/Decisions/ (if not already present)
  - vault-template/Shared/Patterns/ → [vault root]/Shared/Patterns/ (if not already present)
  - vault-template/ → removed after deploy

CLAUDE.md
  - Project name: [name]
  - Description: [summary]
  - Directory structure: [filled in]
  - Technologies: [list]
  - Vault path: [path]
  - Regulatory context: [list]
  - Constraints: [list]
  - Skills table: [updated to reflect confirmed skills]
  - Agents table: [updated to reflect confirmed agents]
  - MCPs section: [updated]

.claude/settings.local.json
  - [List any permissions being added based on MCPs confirmed above]

.claude/agents/session-start.md
  - Vault path hardcoded to: [path]
  - PM tool section: [Jira with project keys / none]

.claude/agents/ - removing:
  - [list of agents being removed if any]
```

Ask: "Does this look right? Anything to change before I write?"

Wait for explicit confirmation before proceeding.

---

## Step 9 - Write

Make all confirmed edits:

### CLAUDE.md

Fill in every template placeholder based on the answers gathered. Sections to update:

- **What This Project Is** - project description
- **Repository / Directory Structure** - from step 1
- **Key Technologies** - from step 1
- **Scaffold repo path** - replace `_fill in_` with the confirmed path from step 1, question 5
- **Active Workstreams** - write: "See `Workstreams/` in the project Obsidian vault." (do not invent workstreams)
- **Constraints Specific to This Project** - from step 3 (git restrictions, no local apply, etc.)
- **Regulatory Context** - from step 2, with hard limits noted for any active standards
- **Vault root** and **Project folder** - from step 5 (two separate fields; vault root is the shared brain, project folder is the working space for this project)
- **Available Tools - MCPs** - fill in the table with confirmed MCPs
- **Available Tools - Skills** - list only the kept skills; mark `/pci-compliance` as "Required before any PCI-impacting change" if PCI is active; note any stubs as "(stub - needs authoring)"
- **Available Tools - Agents** - trim to the confirmed agent list

If PCI DSS is active, add a hard-limits block to the Regulatory Context section:

```
**Hard limits (PCI DSS - cannot be overridden):**
- Application layer data (CHD, payment logs, traces from payment applications) must never enter Grafana or any general-purpose observability tool.
- Production environments must remain isolated from non-production at all times.
- All access to the CDE must be authenticated, authorised, logged, and attributable to an individual. Shared accounts are not permitted.
- Private network connectivity is mandatory for all production data paths. No public endpoints in the CDE.
- Manual changes to production without a corresponding IaC change must be captured as IaC debt immediately.
```

Remove all remaining `_fill in_` and `> **Fill this in...** ` markers. Remove the template instruction comment at the top.

### settings.local.json

Add `permissions.allow` entries for the MCPs confirmed in step 4. Standard mappings:

- Jira/Confluence confirmed → add `mcp__atlassian__searchJiraIssuesUsingJql`, `mcp__atlassian__getJiraIssue`, `mcp__atlassian__getConfluencePage`, `mcp__atlassian__getPagesInConfluenceSpace`, `mcp__atlassian__searchConfluenceUsingCql`
- GitLab MCP confirmed → add `mcp__gl__glab_repo_list`, `mcp__gl__glab_api`, `mcp__gl__glab_mr_view`, `mcp__gl__glab_ci_get`
- Grafana confirmed → add `mcp__grafana__search_dashboards`, `mcp__grafana__get_dashboard_by_uid`, `mcp__grafana__query_prometheus`, `mcp__grafana__list_datasources`, `mcp__grafana__grafana_api_request`
- Obsidian → add `mcp__obsidian-vault__list_directory`, `mcp__obsidian-vault__read_note`, `mcp__obsidian-vault__read_multiple_notes`, `mcp__obsidian-vault__write_note`, `mcp__obsidian-vault__search_notes`, `mcp__obsidian-vault__patch_note`
- Terraform in use → add `Bash(terraform fmt *)`, `Bash(terraform validate *)`

Do not add permissions for tools the user did not confirm. Do not remove any existing entries.

### Global skills symlink

If the symlink was missing in step 0, create it now using the confirmed scaffold path:

```shell
ln -s <scaffold-path>/skills ~/.claude/skills
```

If `~/.claude/skills` already exists (as a symlink or directory), skip this step.

### .claude/agents/session-start.md

Hardcode the vault path. Replace the generic `[vault path]` reference with the absolute path confirmed in step 5.

Update the PM tool section:
- If Jira: replace generic JQL with the confirmed project keys (e.g. `project in (PROJ1, PROJ2)`)
- If no PM tool: remove the Jira query section entirely and note "No PM tool configured for this project."

### .claude/agents/ - unused agents

If terraform-preflight is not needed: delete `.claude/agents/terraform-preflight.md`
If pci-impact is not needed: delete `.claude/agents/pci-impact.md`

Only delete if the user confirmed "no" - do not delete on "uncertain".

### vault-template/ - deploy to Obsidian

Now that the vault path is known, deploy the vault template.

The vault template contains three parts:
- `Project/` - project-specific structure, deployed to the project subfolder
- `Claude/` - shared reference notes, deployed to vault root once and never overwritten
- `Shared/` - cross-project knowledge areas (Technical Reference, Decisions, Patterns), deployed to vault root once and never overwritten

Locate the template - check project root first, fall back to scaffold:
```shell
if [ -d "./vault-template" ]; then TEMPLATE_SRC="./vault-template"; else TEMPLATE_SRC="$SCAFFOLD/vault-template"; fi
```

Set vault paths from step 5 answers:
```shell
VAULT_ROOT="<absolute vault root from step 5>"
PROJECT_FOLDER="<project folder path from step 5>"
```

Create the project folder structure:
```shell
mkdir -p "$VAULT_ROOT/$PROJECT_FOLDER/Workstreams" "$VAULT_ROOT/$PROJECT_FOLDER/Plans" "$VAULT_ROOT/$PROJECT_FOLDER/Session Summaries"
```

Deploy `Project/` template files to the project subfolder:
```shell
cp -r "$TEMPLATE_SRC/Project/." "$VAULT_ROOT/$PROJECT_FOLDER/"
```

Deploy `Claude/` to vault root only if it does not already exist:
```shell
[ ! -d "$VAULT_ROOT/Claude" ] && cp -r "$TEMPLATE_SRC/Claude/" "$VAULT_ROOT/Claude/"
```

Deploy `Shared/` subdirectories to vault root only if each does not already exist (idempotent - never overwrite existing cross-project knowledge):
```shell
for dir in "Technical Reference" "Decisions" "Patterns"; do [ ! -d "$VAULT_ROOT/Shared/$dir" ] && mkdir -p "$VAULT_ROOT/Shared/$dir" && cp "$TEMPLATE_SRC/Shared/$dir/_index.md" "$VAULT_ROOT/Shared/$dir/_index.md"; done
```

If `./vault-template/` exists in the project root (manual scaffold copy state), remove it after deploying:
```shell
[ -d "./vault-template" ] && rm -rf ./vault-template/
```

Report the folder structure that was created.

---

## Step 10 - Done

Report what was changed and moved (file paths only, one line each). Then say:

"Project init complete. Recommended next steps:
1. Run `/claude-obsidian:wiki` to scaffold and populate the Obsidian vault space.
2. Verify `.claude/settings.local.json` has the permissions you need - add more as you discover what tools you reach for.
3. The session-close agent will write session summaries to your vault. Trigger it by saying 'wrap up'."

If PCI was confirmed in scope, add: "Remember to run `/pci-compliance` before implementing any change that touches [list the in-scope systems]."
