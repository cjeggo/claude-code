---
name: vault-propagate
description: "Post-ingest vault propagation. Given recently created or updated notes, searches the entire vault for related pages and updates them with new context. Flags contradictions. No namespace boundaries - vault-wide. Triggers automatically after wiki-ingest completes, or on demand: 'propagate', 'update related notes', 'cross-reference vault', 'push context through vault'."
---

# vault-propagate: Vault-Wide Context Propagation

Push new context through all related vault pages after any ingest or significant update. The vault rewrites itself - new knowledge doesn't live in isolation.

---

## When to Run

- Automatically as a post-step after `claude-obsidian:wiki-ingest` completes
- After `session-close` when new decisions or architecture changes were recorded
- On demand when the user says "propagate", "update related notes", "cross-reference vault"

---

## Input

Derive from context (do not ask the user):
- The list of notes just created or updated (from the ingest output or session summary)
- OR a single note path the user specifies

If context is ambiguous, check `wiki/log.md` or the project's `Session Summaries/` folder for the most recent ingest entry.

---

## Step 1: Extract Propagation Targets

Read the source notes. Extract:

- **Named entities**: people, organisations, systems, services, products, repos, clusters, environments
- **Concepts**: architectural decisions, patterns, constraints, standards, known issues
- **Status changes**: anything that was previously X and is now Y (resolved, deprecated, decided, blocked)
- **New facts**: numbers, dates, URLs, configuration values, versions

Group into a short list (10 items max). If you have more, prioritise entities over concepts, and status changes above both.

---

## Step 2: Search for Related Pages

For each item in your propagation target list, search the vault:

```
mcp__obsidian-vault__search_notes(query: "[entity or concept name]")
```

Collect all matches. Deduplicate. Then exclude:

- The source notes themselves
- Meta and index files: `index.md`, `hot.md`, `overview.md`, `log.md`, `_index.md`, `dashboard.md`
- Anything in `Archive/` or `zArchive/`
- Template files

You now have a candidate list of pages to potentially update.

---

## Step 3: Triage - Prioritise Ruthlessly

Classify each candidate:

| Priority | Criteria |
|----------|----------|
| **High** | The page is directly about one of the extracted entities. Its primary subject is something the new notes changed or extended. |
| **Medium** | The page mentions the entity or concept in a meaningful way - it would be noticeably incomplete without the new context. |
| **Low** | Tangential mention only. |

**Read and update only High and Medium pages.** Hard cap: 15 pages per propagation run. If you have more High+Medium candidates than that, take the 15 most recently edited (most actively used).

---

## Step 4: Update Related Pages

For each High and Medium page:

1. Read the current content.
2. Ask: does the new ingest add something this page should know about?
   - A status that changed
   - A decision that was made
   - A contradiction with what the page currently claims
   - New context that materially extends what the page says

3. **If yes - add context surgically.** Do not rewrite. Options:
   - Append a brief note under the relevant section
   - Update a status field or date in frontmatter
   - Add a wikilink to the new source
   - Add a callout where appropriate

4. **If it contradicts existing content:**
   - On the existing page, add:
     ```
     > [!contradiction] Conflict with [[New Source]]
     > This page claims X. [[New Source]] says Y. Needs resolution.
     ```
   - On the new source note, add a matching callout referencing the existing page.
   - Do not silently overwrite old claims.

5. **If it confirms existing content:** no update needed unless a date or status changed.

---

## Step 5: Log the Propagation Run

Append to the vault log. Use the active project's log file if one exists, otherwise append to a top-level `propagation-log.md`:

```markdown
## [YYYY-MM-DD] propagate | [Source Title or Session Date]
- Source notes: [[Note 1]], [[Note 2]]
- Pages updated: [[Page A]], [[Page B]], [[Page C]]
- Contradictions flagged: [[Page D]] conflicts with [[Note 1]] on [topic]
- Skipped (Low priority): [count] pages
```

---

## What NOT to Do

- **Do not rewrite entire pages.** Surgical additions only. Preserve structure, voice, and existing content.
- **Do not create new pages.** Propagation is update-only. If new pages are needed, that belongs in the ingest step.
- **Do not propagate boilerplate.** File paths, template scaffolding, and generic dates are not knowledge. Only propagate substantive new context.
- **Do not update Low priority pages.** Scope creep here wastes tokens and degrades note quality.
- **Do not recurse.** Propagation runs once over the candidate list. Do not re-derive new targets from the pages you just updated.

---

## Context Window Discipline

- 15 pages hard cap per run.
- Read the most recent ingest log entry first - it may already contain context that removes candidates.
- If a vault has `wiki/hot.md`, read it before searching - it carries recent context and may make some searches unnecessary.
- Use `mcp__obsidian-vault__patch_note` for targeted field updates rather than a full rewrite.
