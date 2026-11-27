---
name: internal-mathparser-protect-workspace
description: >-
  Internal MathParser workspace backup rules: protect dirty sources before
  editing, and stage checkpoints after each successful self-sufficient stage
  of a large change (documentation needs no dirty-tree backup).
  Not a user entry point — load only when referenced by mathparser-add-or-fix
  or mathparser-refactor.
disable-model-invocation: true
---

# Internal: Protect Uncommitted Work Before Editing

Load **before the first edit** to any source file or script you might change, and again whenever a multi-stage task needs a **stage checkpoint** (below).

## Check

Use `git status` for the **source files and scripts** you will touch: `MathParser*.bas`, `tests/SmokeTest_MathParser.bas` (and other `tests/*.bas`), `cpp/MathParser*.cpp` / `.hpp`, `cpp/tests/Tests_MathParser.cpp`, generated test data (`tools/*_generated*.bas`, `tools/*_generated*.cpp.inc`), other SmartMath/Basic/C++ sources, and scripts (`*.bat`, `tools/*.py`).

Documentation needs no backup: `USAGE_AND_SYNTAX.md`, `README.md`, `docs/`, `changelog.txt`, and `.cursor/` skills, flows, and rules.

An untracked file that existed before the task counts as dirty (git has no copy of it). Files the agent created during the task do not need a backup.

Unsaved editor changes are not on disk, so neither git nor a file copy captures them. If the open-files list shows a file you will touch as modified/unsaved, ask the user to save it before editing.

If those paths are clean, no backup is required.

## If dirty — backup first

Create a backup **before** any edit, revert, reset, `git checkout` / `git restore` / `git stash push` that could lose work:

1. **Required:** copy each affected file to `tools/backup/<filename>.<YYYYMMDD-HHMMSS>.bak` (create `tools/backup/` if needed). Use a filesystem copy — do not rely on git alone.
2. **Optional extra:** `git stash store -m "agent-backup-before-<task-summary>" $(git stash create)` records tracked changes without touching the working tree; only in addition to the file copy, and only when tracked files have changes (otherwise `git stash create` prints nothing and `store` fails). Never use `git stash push` for a backup: it reverts the files it stashes and skips untracked files.
3. In the first progress note to the user, list the **exact** backup path(s).
4. **Forbidden without explicit user request:** `git checkout HEAD -- <file>`, `git restore --source=HEAD <file>`, or any overwrite of the user’s uncommitted version. Recover from the timestamped copy or ask the user.
5. If you already overwrote a file by mistake: stop editing, say so immediately, help recover from backup / IDE local history / `git stash list` — do not repeat destructive git commands.

Applies to feature work, fixes, refactors, reorder passes, and test-only edits that touch source files or scripts. To inspect `HEAD` without touching the working tree, use `git show HEAD:<path>` or a temporary `git worktree` outside the repo (remove it with `git worktree remove` when done).

## Stage checkpoints (large / multi-stage work)

When a task has **several self-sufficient stages** (a written plan with steps, or an unplanned sequence that still breaks into complete features), create a filesystem checkpoint **after each successful stage**, before starting the next. Purpose: reverting a later stage must not wipe already verified progress from earlier stages.

### What counts as a stage

A stage is a **complete, meaningful unit** of the change — guided by importance and completeness, not by a clock:

- Prefer plan steps when the plan names concrete stages (e.g. shared helper, then call sites, then tests, then skills, then gates).
- Without a plan (or when stages are vague): use judgement — e.g. “Basic+C++ behavior wired and compiling”, “tests locked”, “skills updated”, “one refactor cluster done and the side compiles”.
- Do **not** checkpoint mid-feature (half a helper, half a test table) unless that mid-work already took a long time **and** contains a separable, important subset worth restoring alone.
- Do **not** checkpoint too often (every tiny edit or every few minutes). One checkpoint per completed stage is the default.

Gates that only run (no further source edits) need no stage checkpoint. If a gate failure forces more source edits, treat the fix as a new stage: checkpoint the currently good tree **before** those fix edits when a prior stage was already complete.

### How to checkpoint

1. Copy every source/script file that stage completed (and that later stages may overwrite) to `tools/backup/<filename>.<YYYYMMDD-HHMMSS>.bak`. Use **one shared timestamp** per stage so the set is obvious. Create `tools/backup/` if needed. Prefer the post-stage contents (the verified progress to preserve).
2. List the exact backup path(s) in the progress note for that stage.
3. Same forbidden git restores as above; do not use `git stash push` for stage checkpoints.
4. Documentation / `.cursor/` skills normally skip the dirty-tree backup above. If a stage’s deliverable **is** skill/flow/doc updates, still stage-checkpoint those files the same way so a later stage rollback can restore them.

A stage checkpoint is in addition to the dirty-tree backup before the **first** edit of the task (when that rule applies). Later stages re-copy the current files; keep earlier stage timestamps — do not delete prior `.bak` files from this task.
