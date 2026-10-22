# Tools & MCPs

Reference for plugins, MCP servers, skills, and subagent types available in Claude Code sessions. Not all of these are configured in every project - check `claude mcp list` in the project context.

---

## Installed Plugins

Plugins are installed at user scope (`~/.claude/plugins/`) and are available across all projects. Install via `/plugin` in Claude Code, then `/reload-plugins`.

| Plugin | Slug | Source | Version | What it provides |
|--------|------|--------|---------|-----------------|
| context-mode | `context-mode@context-mode` | github: `mksglu/context-mode` | 1.0.151 | Context window protection MCP - runs commands and indexes output; returns search results not raw output. Use `ctx_batch_execute` for any command producing >20 lines. |
| superpowers | `superpowers@claude-plugins-official` | github: `anthropics/claude-plugins-official` | 5.1.0 | Workflow meta-skills - plans, TDD, parallel agents, debugging, branch close-out. `/superpowers:<skill-name>`. |
| context7 | `context7@claude-plugins-official` | github: `anthropics/claude-plugins-official` | - | Library docs MCP - fetches current docs for any framework/SDK/API from source. Use before debugging library errors or checking API syntax. |
| claude-obsidian | `claude-obsidian@claude-obsidian-marketplace` | github: `AgriciDaniel/claude-obsidian` | 1.6.0 | Full Obsidian wiki workflow - ingest, lint, query, save, canvas. `/claude-obsidian:<skill-name>`. |
| obsidian | `obsidian@obsidian-skills` | github: `kepano/obsidian-skills` | 1.0.1 | Obsidian format/syntax skills - markdown, canvas JSON, CLI, bases. `/obsidian:<skill-name>`. |

To update a plugin: `/plugin` again then select update. For context-mode: `/ctx-upgrade`.

---

## MCP Servers

### obsidian-vault

**What it does:** Read, write, search, and manage notes in the local Obsidian vault.

**Key tools:**
- `read_note` / `write_note` - read or overwrite a note at a vault-relative path
- `patch_note` - append or prepend content without overwriting
- `search_notes` - full-text search across the vault
- `list_directory` - list files and subdirectories at a vault path
- `move_note` / `move_file` - relocate notes
- `get_vault_stats` - summary of vault size and note count
- `manage_tags` / `list_all_tags` - tag management
- `read_multiple_notes` - batch read several notes in one call

**When to use:** Primary tool for reading project context and writing working notes, drafts, trackers, and reference material. This is the project brain.

---

### atlassian

**What it does:** Atlassian Cloud access - Confluence (documentation) and Jira (issue tracking).

**Default access level:** Read only. Never edit Confluence or transition Jira issues without explicit permission.

**Key tools:**
- `getConfluencePage` - fetch a page by ID
- `searchConfluenceUsingCql` - CQL search across spaces
- `getPagesInConfluenceSpace` - list pages in a space
- `getJiraIssue` - fetch a Jira issue
- `searchJiraIssuesUsingJql` - JQL query
- `createConfluencePage` / `updateConfluencePage` - create or update pages (requires explicit permission)
- `createJiraIssue` / `editJiraIssue` - create or update issues (requires explicit permission)
- `transitionJiraIssue` - move issue to a new status (requires explicit permission)
- `addCommentToJiraIssue` - add a comment (requires explicit permission)

**Constraints:**
- Resolve page/issue IDs to human-readable names before asking for permission to edit anything.
- If content looks contradictory or obsolete, ask for clarification - do not assume.

---

### gl (glab)

**What it does:** GitLab CLI operations via the `glab` tool - repos, MRs, issues, CI/CD pipelines.

**Key tools:**
- `glab_mr_create` / `glab_mr_view` / `glab_mr_list` - merge request management
- `glab_ci_list` / `glab_ci_trace` / `glab_ci_status` - pipeline monitoring
- `glab_ci_retry` / `glab_ci_cancel_job` - pipeline control
- `glab_issue_view` / `glab_issue_list` - issue reading
- `glab_repo_list` / `glab_repo_view` - repository browsing
- `glab_api` - raw GitLab API calls for anything not covered by named tools

**Constraints:**
- Only query groups directly related to the active project unless explicit permission is granted.
- Always use local repos as the first option; go to GitLab only when something is not available locally.
- MRs must be draft MRs. Only create when the user says they are ready.
- May monitor pipelines and attempt fixes on the MR branch only.

---

### grafana

**What it does:** Full Grafana stack access - dashboards, datasources, alerting, Loki, Prometheus, Tempo, OnCall, Incidents.

**Key tools:**
- `search_dashboards` / `get_dashboard_by_uid` / `update_dashboard` - dashboard management
- `query_prometheus` / `list_prometheus_metric_names` - PromQL queries
- `query_loki_logs` / `list_loki_label_names` - LogQL queries
- `alerting_manage_rules` / `alerting_manage_routing` - alert rule and notification policy management
- `list_incidents` / `create_incident` - incident management
- `get_datasource` / `list_datasources` - datasource inspection
- `create_annotation` - add annotations to dashboards
- `grafana_api_request` - raw API call for anything not covered by named tools

**When to use:** Inspecting dashboards, querying metrics during incidents, building or modifying alert rules, checking datasource configuration.

---

### plugin_context-mode_context-mode (ctx)

**What it does:** Context window protection. Runs commands and indexes their output into a local FTS5 store; returns search results rather than raw output. Prevents large command outputs from flooding the context window.

**Key tools:**
- `ctx_batch_execute` - PRIMARY tool. Run multiple commands + search queries in one call. Use for any output expected to exceed 20 lines.
- `ctx_search` - search the indexed store with multiple queries
- `ctx_execute` - run a single command and index it
- `ctx_fetch_and_index` - fetch a URL and index it (replaces WebFetch)
- `ctx_stats` - show context savings statistics
- `ctx_purge` - wipe the knowledge base (irreversible - warn before using)
- `ctx_upgrade` - upgrade the context-mode plugin

**Rule:** Use `ctx_batch_execute` instead of Bash for any command that produces more than ~20 lines. Never use Bash to pipe large outputs into context.

---

### Lucid Chart

**What it does:** Creates and edits Lucid diagrams - architecture diagrams, flowcharts, sequence diagrams.

**Constraints:**
- Break diagram work into small chunks. Lucid is prone to context window exhaustion on large diagrams.
- Use Azure icons and follow Microsoft standard architectural diagram patterns for cloud infrastructure diagrams.
- Do not attempt a full complex diagram in one shot - sketch, confirm, then add detail incrementally.

---

## Skills (Slash Commands)

Skills are invoked via `/skill-name` or `/plugin:skill-name` in the prompt. They load additional instructions and set up specialised behaviour for the session.

Project-local skills live in the project's `.claude/skills/` directory and take priority for project work. Global plugin skills (claude-obsidian) are available across all projects.

---

### Project-Local Skills

These live in `.claude/skills/` within the project directory. They are the primary skills for day-to-day infrastructure work.

---

#### /pci-compliance

**What it does:** Checks proposed changes against PCI DSS requirements. Covers all 12 core requirements with particular depth on network security, cardholder data protection, access control, and audit logging. Includes compliance checklists, data minimisation guidance, tokenisation patterns, and encryption standards.

**When to use:** Required before implementing any change that could affect PCI compliance. If the answer to "will this affect PCI compliance?" is yes or uncertain, invoke this skill before proceeding.

---

#### /azure-enterprise-infra-planner

**What it does:** Architects and plans enterprise Azure infrastructure from workload descriptions. Covers networking (hub-spoke, VNets, firewalls, private endpoints), identity, security, compliance, and multi-resource topologies aligned to the Azure Well-Architected Framework. Can generate Bicep or Terraform directly. Has access to Azure best practices MCP tools and WAF service guides.

**When to use:** Planning new Azure infrastructure, designing network topology, evaluating multi-region or DR approaches, or when you need WAF-aligned recommendations before writing Terraform.

---

#### /azure-kubernetes

**What it does:** AKS cluster configuration, design decisions, and best practices. Covers cluster type selection, networking (CNI, egress, ingress, dataplane), security, observability, upgrades, patching, node pools, reliability, and cost controls. Knows the specific constraints of private AKS clusters.

**When to use:** AKS cluster design decisions, evaluating networking options, reviewing security configuration, planning node pool changes, or any question about AKS-specific behaviour.

---

#### /terraform-engineer

**What it does:** Terraform IaC specialist. Covers module development, state management, backend migration, importing existing resources, resolving state conflicts, provider configuration, multi-environment workflows, and infrastructure testing. Knows AWS, Azure, and GCP providers.

**When to use:** Writing or refactoring Terraform modules, managing state, importing existing Azure resources, debugging plan/apply errors, or designing the IaC structure for a new workload.

---

#### /kubernetes-specialist

**What it does:** Kubernetes workloads expert. Covers deployment manifests, pod security, RBAC, NetworkPolicy, ArgoCD/GitOps, Helm charts, storage, performance optimisation, multi-cluster management, and CRDs. Knows the specific patterns used in this project (ApplicationSet, AppProject, argocd-cm labels).

**When to use:** Writing or reviewing Kubernetes manifests, ArgoCD Application/ApplicationSet configuration, Helm chart development, RBAC design, or debugging pod/workload issues.

---

#### /gitlab-ci-patterns

**What it does:** GitLab CI/CD pipeline patterns for Terraform, container builds, multi-environment deployments, security scanning, caching, and dynamic child pipelines. Knows the pipeline template structure used in this project (`terraform-project@main`, `terraform-module@main`).

**When to use:** Writing or debugging GitLab CI pipelines, adding new pipeline stages, troubleshooting pipeline failures, or designing new CI/CD flows for a project.

---

#### /monitoring-expert

**What it does:** Observability specialist. Covers Prometheus metrics and alerting rules, structured logging, OpenTelemetry tracing, Grafana dashboards, SLO definitions, and load testing. Knows PromQL and LogQL.

**When to use:** Writing Prometheus alert rules, designing SLOs, reviewing Grafana dashboard queries, setting up structured logging, or planning the observability approach for a new component.

---

#### /sre-engineer

**What it does:** SRE practices. Covers SLO and error budget definition, multi-window burn rate alerting, PromQL golden signal queries, toil automation, and incident response procedures.

**When to use:** Defining SLOs for a service, writing production alerting rules, designing error budget policies, or planning incident response runbooks.

---

#### /devops-engineer

**What it does:** CI/CD pipelines, container builds, deployment automation, and rollback procedures. Provides pipeline templates, Dockerfile patterns, and structured rollback runbooks.

**When to use:** Designing deployment pipelines, writing Dockerfiles, planning blue/green or canary deployments, or drafting rollback procedures.

---

### claude-obsidian Skills

These are provided by the `claude-obsidian` plugin and cover the full Obsidian wiki workflow.

---

#### /claude-obsidian:wiki

**What it does:** Sets up and manages an Obsidian vault as a project knowledge base. Checks vault state, MCP server config, and scaffolds the structure based on the project type. If the vault is already set up, checks what has been ingested recently and offers to pick up where things left off.

**When to use:** Starting a new project, resuming after a long break, or restructuring an existing vault.

---

#### /claude-obsidian:wiki-ingest

**What it does:** Parallel batch ingestion agent. Processes multiple sources simultaneously - each source is fully read, entities and concepts extracted, filed, and the index updated. Dispatches one agent per source.

**When to use:** When multiple files are dropped into `.raw/` or the user says "ingest all" / "batch ingest" / "process everything in `.raw/`".

---

#### /claude-obsidian:wiki-lint

**What it does:** Comprehensive wiki health check. Scans for orphan pages, dead links, stale claims, missing cross-references, frontmatter gaps, and empty sections. Generates a structured lint report.

**When to use:** After a burst of ingestion, periodically to keep the vault clean, or when the user says "lint the wiki" / "health check" / "wiki audit".

---

#### /claude-obsidian:wiki-fold

**What it does:** Extractive log rollup. Summarises a sequence of session logs or journal entries into a compact fold entry without hallucinating content. Preserves key facts and decisions; discards session noise. Reversible.

**When to use:** When a session log has grown long and needs compacting, or before archiving a completed workstream.

---

#### /claude-obsidian:wiki-query

**What it does:** Query the wiki vault intelligently. Three modes: Quick, Standard, and Deep. Files significant answers back into the vault as synthesis notes.

**When to use:** Questions requiring synthesis across multiple vault notes - "what is the current state of X?" or "what decisions have we made about Y?".

---

#### /claude-obsidian:autoresearch

**What it does:** Autonomous research loop. Searches the web, synthesises findings into structured vault notes, and reports what was created.

**When to use:** Background research on a technology or standard where findings should be filed into the vault directly.

---

#### /claude-obsidian:canvas

**What it does:** Visual layer of the wiki. Add images, text cards, PDFs, and wiki pages to Obsidian canvas files with auto-positioning inside zones.

**When to use:** Building visual maps of architecture decisions or creating spatial overviews of a complex workstream.

---

#### /claude-obsidian:defuddle

**What it does:** Strips clutter from web pages before ingesting into the vault. Saves 40-60% tokens versus ingesting raw HTML.

**When to use:** Before `/wiki-ingest` on a web article or documentation page where raw content is noisy.

---

#### /claude-obsidian:obsidian-bases

**What it does:** Create and edit Obsidian Bases (`.base` files) - dynamic tables, card views, list views, filters, formulas, and summaries over vault notes.

**When to use:** When a structured view over vault content is needed - task tracker, reading list, entity index, content dashboard.

---

#### /claude-obsidian:save

**What it does:** Saves the current conversation or insight into the vault as a structured note with correct frontmatter and folder placement.

**When to use:** "Save this", "file this", "save to wiki", or at the end of a session to capture decisions before context is lost.

---

### Built-in Claude Code Skills

---

#### /claude-code-guide

**What it does:** Answers questions about the Claude Code CLI, Claude Agent SDK, and the Anthropic API.

**When to use:** "How do I configure a hook?", "Can Claude Code do X?", "How do I use the Anthropic SDK?".

---

#### /statusline-setup

**What it does:** Configures the Claude Code status line setting shown in the terminal.

---

## Subagent Types (Agent Tool)

Subagents are spawned via the `Agent` tool. Use them for tasks that benefit from isolation, parallelism, or specialised capability. Do not spawn unless the task matches the agent's description - spawning starts cold and re-derives context, so it is the expensive path.

| Type | Best for |
|---|---|
| `Explore` | Fast read-only code/file search. Specify: target, breadth (quick/medium/thorough), whether to return paths or content. |
| `Plan` | Architecture and implementation planning. Returns step-by-step plans, identifies critical files, considers tradeoffs. |
| `general-purpose` | Multi-step research, cross-repo investigation, tasks that span many files or systems. |
| `claude-code-guide` | Questions about Claude Code CLI, Claude Agent SDK, or the Anthropic API. |
| `claude-obsidian:wiki-ingest` | Batch ingestion of multiple sources into the vault in parallel. |
| `claude-obsidian:wiki-lint` | Full vault health check. |
| `statusline-setup` | Configure the Claude Code status line. |

**When not to spawn:** If the target is already known (use Read or grep directly). If it would duplicate work already done in the main context. If the task is small enough to handle inline.
