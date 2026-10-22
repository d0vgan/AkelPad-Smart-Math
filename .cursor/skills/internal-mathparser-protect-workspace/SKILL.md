---
name: internal-mathparser-protect-workspace
description: >-
  Internal MathParser workspace backup rules before editing shared parser sources.
  Not a user entry point — load only when referenced by add-mathparser-function
  or parser-reusability-cleanup.
disable-model-invocation: true
---

# Internal: Protect Uncommitted Work Before Editing

Load **before the first edit** to any file you might change.

## Check

Use `git status` and/or dirty editor tabs for paths you will touch (especially `MathParser.bas`, `SmokeTest_MathParser.bas`, `cpp/MathParser.cpp`, `cpp/MathParser.hpp`, and other SmartMath/Basic sources).

If those paths are clean, no backup is required.

## If dirty — backup first

Create a backup **before** any edit, revert, reset, `git checkout` / `git restore` / `git stash` that could lose work:

1. **Required:** copy each affected file to `tools/backup/<filename>.<YYYYMMDD-HHMMSS>.bak` (create `tools/backup/` if needed). Use a filesystem copy — do not rely on git alone.
2. **Optional extra:** `git stash push -m "agent-backup-before-<task-summary>" -- <paths>` — only in addition to the file copy, never instead of it.
3. In the first progress note to the user, list the **exact** backup path(s).
4. **Forbidden without explicit user request:** `git checkout HEAD -- <file>`, `git restore --source=HEAD <file>`, or any overwrite of the user’s uncommitted version. Recover from the timestamped copy or ask the user.
5. If you already overwrote a file by mistake: stop editing, say so immediately, help recover from backup / IDE local history / `git stash list` — do not repeat destructive git commands.

Applies to feature work, refactors, reorder passes, and test-only edits that touch shared sources.
