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

Use its parity/build/test rules as mandatory constraints for all refactor work.

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
   - Compile/test after each cluster when practical.

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

Run relevant gates from `add-mathparser-function` skill:

- Basic parser changed: `Compile.bat` (if required by that skill).
- Basic parser/tests changed: `RunSmokeTests.bat`.
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

