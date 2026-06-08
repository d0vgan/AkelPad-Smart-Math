---
name: parser-reusability-cleanup
description: Review and refactor Basic/C++ parser code for reusability and cleanup. Use when the user asks to extract duplicate code, reuse/update helpers, simplify without behavior or performance regressions, improve maintainability, or remove legacy/unused/dead parser code.
---

# Parser Reusability Cleanup

## Purpose

Perform behavior-preserving, efficiency-safe cleanup/refactor passes on:

- `MathParser.bas`
- `cpp/MathParser.cpp`
- `cpp/MathParser.hpp`

This skill is for maintenance/refactoring only (not feature additions).

## Required prerequisite

Before making changes, read and follow:

- `.cursor/skills/add-mathparser-function/SKILL.md`

Use its parity/build/test rules as mandatory constraints for all refactor work, including:

- **Protect uncommitted work before editing (Required)** in that skill — mandatory backup of local changes before the first edit; never overwrite uncommitted files via `git checkout` / `git restore` without explicit user approval.
- **Compile and build error discipline (Required)** in that skill.
- **Test and guard execution order (Required)** in that skill — run all test builds and executables sequentially; when both Basic and C++ gates are required, complete every required Basic compile/run gate before starting C++ build/test.

## Protect uncommitted work before editing (Required)

Refactors on `MathParser.bas` and mirrored C++ sources are high-risk for accidental loss of large uncommitted edits.

**Before the first edit**, follow the same rule as in `add-mathparser-function` (**Protect uncommitted work before editing (Required)**):

- If `git status` (or dirty editor tabs) shows local changes in paths you will touch, copy each file to `tools/backup/<filename>.<timestamp>.bak` **before** any modification.
- Tell the user the backup path(s) in your first update.
- Do **not** use `git checkout HEAD -- …`, `git restore --source=HEAD …`, or “reset to clean tree” on those files to fix a bad refactor — restore from the timestamped copy or ask the user.
- `git stash` alone is **not** sufficient backup.

## Compile and build error discipline (Required)

When a build or compile step fails during cleanup work, follow the same rules as in `add-mathparser-function` (**Compile and build error discipline (Required)**). In short:

- Assume the compiler/toolchain is right; a "compiler bug" is a last-resort hypothesis.
- Fix the **first meaningful error** only; ignore cascading follow-on errors until it is resolved.
- Make the **smallest** direct fix; keep diffs small and reversible (**one hypothesis → one edit → one compile**; roll back if diagnostics do not improve).
- Before blaming the compiler, check: modified files, imports/includes, types, generated code, build flags, stale caches, dependency versions, API changes (including Basic/C++ parity drift).
- After **3** failed fix-compile iterations on the same primary error, stop, summarize facts, and ask for human review — do not invent workarounds.

## What to optimize

Focus on these goals:

1. Identify duplicate logic blocks and extract/reuse helpers.
2. Prefer existing helpers first; update existing helpers before creating new ones.
3. Simplify control flow and reduce maintenance burden.
4. Preserve existing behavior and error text semantics.
5. Preserve or improve runtime efficiency (no accidental slow paths).
6. Detect and remove legacy/unused/dead code with evidence.

## Hard constraints

- No behavior change unless explicitly requested.
- No user-visible error message drift unless explicitly requested.
- No UB in C++.
- Keep Basic/C++ parity for mirrored logic.
- Avoid unnecessary allocations/copies in hot paths.
- Do not replace iterator-style walks with eager flattening unless required by semantics.
- Keep string constants naming conventions (`FB_STR_*`, `STR_*`).
- If a cleanup/refactor introduces or changes behavior for a builtin operator/function path, explicitly decide whether non-finite values (`inf`, `-inf`, `nan`) are accepted or rejected based on common math and calculator behavior; keep Basic/C++ parity and lock with tests.

## Refactor workflow

1. **Inventory duplicates**
   - Find repeated loops/branches/validation/error patterns.
   - Rank by: impact, risk, and testability.

2. **Choose helper strategy**
   - Prefer reusing current helpers.
   - If near-match exists: extend/tune it and migrate call sites.
   - If no fit exists: add a narrowly scoped helper.

3. **Preserve efficiency**
   - Keep single-pass traversal where possible.
   - Keep pre-count + single allocation patterns.
   - Avoid extra temporary containers in hot paths.
   - Keep scratch-buffer reuse patterns in C++.

4. **Apply changes in small slices**
   - Refactor one logical cluster at a time.
   - Compile/test after each cluster when practical; run gates **sequentially** per **Test and guard execution order (Required)** (Basic compile/run gates before C++ when both are needed).
   - On compile failure, use **Compile and build error discipline (Required)** — do not stack multiple refactor hypotheses in one edit.

5. **Dead code removal**
   - Remove only when unused/unreachable is confirmed.
   - If uncertain, keep and annotate in report as candidate.

## Dead/unused code criteria

Treat code as removable only if one of these is true:

- No references/call sites in repo and not part of required external API.
- Provably unreachable branch under current enclosing guards.
- Fully superseded helper with no remaining use.

For each removal, record short justification in final report.

## Validation gates (mandatory)

Run relevant gates from `add-mathparser-function` skill, following **Test and guard execution order (Required)** there:

- **Never** compile or run Basic and C++ test gates in parallel.
- Run each gate sequentially: one compile+run cycle must finish successfully before the next starts.
- When both sides are required, run Basic gates first (each to completion), then C++:
  - Basic parser changed: `Compile.bat` (if required by that skill).
  - Basic parser/tests changed: `RunSmokeTests.bat`.
  - **After all required Basic gates pass:**
  - C++ parser/tests changed:
    - `cpp/BuildTests_vc2022_x64.bat`
    - `cpp/MathParserTests.exe`

All required gates must pass before completion.

## Completion report format

When done, report:

- Files changed.
- Duplicate patterns eliminated (brief list).
- Helper reuse/extraction summary.
- Dead code removed with reason.
- Efficiency notes (why no slowdown expected).
- Basic/C++ test outcomes.

