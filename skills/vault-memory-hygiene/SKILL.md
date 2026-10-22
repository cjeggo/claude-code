---
name: vault-memory-hygiene
description: Periodic (not every-session) hygiene pass across the Obsidian vault and harness memory - finds orphaned/broken memory links, closed plans never archived, and one-directional backlinks. Use when the user asks to tidy the vault, audit memory, check for stale notes, or periodically when it's been a while since the last run. Not part of session-close and not invoked automatically every session.
---

# Vault & Memory Hygiene

Mechanical, script-based checks - no LLM cost to detect, judgment only needed to decide what to do about a finding. The vault path and memory directory are project-specific - read the project's CLAUDE.md first if you don't have them (the vault path is usually documented near "Vault path:" or "Project folder:"; the memory directory defaults to `~/.claude/projects/<sanitized-cwd>/memory/` unless the project's settings override it).

**Cadence:** on-demand only - run when the user asks to tidy up, audit memory, or check for stale notes. Not run automatically every session, and not part of `session-close` (session-close handles CLAUDE.md corrections and per-session carry-overs; this handles slower-moving structural drift across the vault and memory directory as a whole).

**Safety:** archive, never delete. The memory directory is typically not git-tracked - a hard delete there is unrecoverable. Move candidates to `archive/` (memory) or `Archive/` (vault) instead, and always confirm with the user before moving anything found by these checks - they're mechanical detections, not automatic fixes.

## Check 1 - Memory index integrity

Two failure modes: files on disk that `MEMORY.md` never indexed (orphans - accumulate silently whenever an old project-state file gets superseded but the file itself is never removed), and index entries pointing at files that don't exist (broken links - happens when a memory file gets deleted/renamed without updating the index).

```bash
MEMDIR=<memory directory for this project>

# Orphans: on disk, not in MEMORY.md
cd "$MEMDIR"
for f in *.md; do
  [ "$f" = "MEMORY.md" ] && continue
  grep -q "($f)" MEMORY.md || echo "ORPHAN: $f"
done

# Broken links: indexed, missing from disk
grep -oE '\]\((feedback|project|reference|user|jira|obsidian)_[a-z0-9_]+\.md\)' MEMORY.md | tr -d '()]' | sort -u > /tmp/indexed.txt
ls "$MEMDIR" | grep '\.md$' | grep -v '^MEMORY.md$' | sort -u > /tmp/ondisk.txt
echo "--- indexed but missing from disk ---"
comm -23 /tmp/indexed.txt /tmp/ondisk.txt
```

For orphans: read each one's frontmatter `description`, decide if it's genuinely superseded/resolved (archive to `$MEMDIR/archive/`) or still-relevant-but-just-unindexed (add it to `MEMORY.md`). For broken links: read the one-line description already in `MEMORY.md` (it's usually enough to reconstruct the file), recreate the memory file properly, or remove the dead index line if the content is truly gone and irrecoverable.

Also check `MEMORY.md`'s own size - if a `PostToolUse` hook warns it's approaching the read-limit cap, compact every entry to a genuine one-liner (no secondary clauses) rather than letting it keep growing; the detail belongs in the linked file, not the index.

## Check 2 - Closed plans never archived

`Plans/` should only ever contain the current head plan plus genuinely open non-weekly work. Superseded weekly plans and explicitly-closed one-off plans accumulate if nothing prompts their removal.

```bash
PLANS=<vault Plans/ folder for this project>
cd "$PLANS"
for f in *.md; do
  grep -m1 -iE "^status:|^\*\*status" "$f"
done
```

Any weekly plan where the week number is earlier than the currently-active head plan's week is closed by construction - a project only ever has one active head plan at a time. Any plan with an explicit `status: done|complete|delivered|historical` (or a `**Status ... DONE**` line) is also a candidate regardless of naming. Confirm with the user only if a plan's closure is ambiguous (`status: draft` or `parked` are not closed, leave them); move confirmed-closed ones to `Archive/Plans/`.

## Check 3 - One-directional backlinks

A note's own `Related: [[X]]` line doesn't guarantee `X` links back - this is a systemic pattern, not a one-off. Detect mechanically:

```bash
python3 -c "
import os, re, glob

vault_root = '<vault root - the shared brain, not just this project's subfolder>'
project_folder = '<this project's vault subfolder>'
all_md = glob.glob(vault_root + '/**/*.md', recursive=True)

link_re = re.compile(r'\[\[([^\]|#]+)')
linked_names = set()
for f in all_md:
    try:
        text = open(f, encoding='utf-8', errors='ignore').read()
    except Exception:
        continue
    for m in link_re.findall(text):
        linked_names.add(m.strip().split('/')[-1].lower())

project_md = glob.glob(project_folder + '/**/*.md', recursive=True)
for f in project_md:
    if '/Archive/' in f:
        continue  # archived notes don't need backlinks
    name = os.path.splitext(os.path.basename(f))[0]
    if name.lower() not in linked_names:
        print(f)
"
```

Filter out `Archive/` results (expected, archived notes are inert by design) and the vault's own root index note if it has one (an entry point is not an orphan). For genuine orphans that reference other notes via their own `Related:` line, add the reciprocal link on the other side - in practice this is the actual fix needed in most real cases, not removal of the orphan itself. For genuine orphans with no `Related:` line at all and no other note that should plausibly reference them, flag for the user rather than guessing where a link belongs.

## Output format

Report findings grouped by check, with counts. Do not archive, delete, or edit anything until the user confirms - this skill's job is to produce an accurate, current report; acting on it is a separate, explicit step.

```
## Vault & Memory Hygiene Report - [date]

### Memory index integrity
- N orphaned memory files (on disk, unindexed): [list or "none"]
- N broken index links (indexed, missing from disk): [list or "none"]
- MEMORY.md size: [current] / [limit if a hook has flagged it]

### Closed plans not archived
- N candidates: [list with reason - "superseded by week N", "status: done", etc.]

### One-directional backlinks
- N orphaned notes found: [list]
- Of these, N have an existing Related: line needing a reciprocal link; N have no clear home

### Recommended actions
[Concrete list - archive X, recreate Y, add link from A to B]
```
