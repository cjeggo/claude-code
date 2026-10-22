---
name: obsidian-index-maintenance
description: Maintains an _index.md in every Obsidian vault folder so notes are found by navigating indexes, never by full-vault search. Use whenever creating a new folder, creating/moving a note anywhere in the vault, or needing to locate a note.
---

# Obsidian Index Maintenance

The vault is navigated via a tree of `_index.md` files, one per folder, rather than full-text
search across the whole vault. This exists so lookups stay cheap (read one small index file,
maybe drill into a subfolder's index) instead of scanning everything every time.

## The rules

1. **Every folder has an `_index.md`.** Creating a new folder means creating its `_index.md` in
   the same action - not a followup, not "later." This includes the vault root.
2. **Every new note gets added to its folder's `_index.md`** at creation time, as a link plus a
   short one-line description of what the note is/covers. Do this in the same turn the note is
   created - don't defer it.
3. **Nested folders each get their own `_index.md`.** A parent folder's index does **not** list
   notes that live inside a child folder - it only links to that child folder's `_index.md`.
   Never let a parent index become a flattened, recursive listing of everything below it; each
   index only owns the direct contents of its own folder (notes) plus one link per direct
   subfolder.
4. **Moving or renaming a note** updates both the old and new folder's `_index.md` (remove from
   old, add to new) in the same action as the move/rename.
5. **Deleting a note** removes its entry from the folder's `_index.md` in the same action.
6. **Looking for a note starts at the index, not a vault-wide search.** Read the vault root's
   `_index.md`, follow links to the relevant subfolder's `_index.md`, and so on, drilling down
   only as far as needed. Full-text search across the vault (`search_notes`, directory listing
   of an un-indexed folder) is a fallback for when the index genuinely doesn't have what's
   needed - not the default lookup path.
7. **Existing folders without an index get one the next time they're actually touched** - lazy
   backfill, not a standing obligation to retroactively index the whole vault on every session.
   (A one-off full backfill was run 2026-08-23 covering the vault as it stood then - anything
   created after that follows rules 1-5 going forward.)

## Index file format

```markdown
---
tags: [index]
---
# <Folder Name> Index

## Notes
- [[Note Title]] - one-line description of what it covers

## Subfolders
- [[Path/From/Vault/Root/To/Subfolder/_index]] - one-line description of what that subfolder is about
```

Link subfolders (and any cross-folder link generally) by their **full path from the vault
root**, not a bare folder name - many folders across the vault share names (e.g. several
`Plans/` folders), so a bare `[[Subfolder/_index]]`-style relative link is ambiguous. A same-
folder note link (rule 2) can stay a bare `[[Note Title]]` as long as that title is unique
vault-wide, which is the normal case.

Omit the `## Notes` or `## Subfolders` heading entirely if that folder has none of that kind -
don't leave an empty heading with nothing under it.

## Why this exists

Rationale: full-vault or full-folder search doesn't scale as the vault
grows, and an index tree makes "where does X live" a cheap, deterministic lookup instead of a
search. This is a standing behavioral rule, not a one-off cleanup task.
