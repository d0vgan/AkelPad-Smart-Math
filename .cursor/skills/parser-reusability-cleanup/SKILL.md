---
name: parser-reusability-cleanup
description: >-
  Review and refactor Basic/C++ parser code for reusability and cleanup. Use
  when the user asks to extract duplicate code, reuse/update helpers, simplify
  without behavior or performance regressions, improve maintainability, or
  remove legacy/unused/dead parser code.
---

# Parser Reusability Cleanup

## Purpose

Behavior-preserving, efficiency-safe cleanup/refactor on:

- `MathParser.bas`
- `cpp/MathParser.cpp`
- `cpp/MathParser.hpp`

Maintenance/refactoring only — not feature additions. For new builtins/constants, use `add-mathparser-function` instead.

## Agent loading rules

Do **not** preload every dependency. Read on demand:

| When | Read |
|---|---|
| Before first edit | `.cursor/skills/internal-mathparser-protect-workspace/SKILL.md` |
| Editing helpers / int metadata / string constants | `.cursor/skills/add-mathparser-function/flows/coding-standards.md` |
| Editing `cpp/MathParser.hpp` / `.cpp`, or moving C++ functions off `MathParser` | `.cursor/skills/add-mathparser-function/flows/cpp-class-design.md` |
| Changing real/complex operator or builtin paths | `.cursor/skills/add-mathparser-function/flows/complex-support.md` |
| Adding or changing test expectations | `.cursor/skills/add-mathparser-function/flows/smoke-tests.md` |
| Mirroring Basic↔C++ | `.cursor/skills/internal-mathparser-basic-cpp-parity/SKILL.md` |
| Before compile/test or choosing gates | `.cursor/skills/internal-mathparser-build-gates/SKILL.md` |

Do not load the full `add-mathparser-function` skill unless the task becomes a feature add.

## What to optimize

1. Extract/reuse helpers for duplicate logic (repeated loops, branches, validation, error text).
2. Prefer extending existing helpers before adding new ones.
3. Simplify control flow; cut maintenance burden.
4. Preserve behavior and error-text semantics.
5. Preserve or improve runtime efficiency (no accidental slow paths).
6. Remove dead/unused code only with evidence.

## Hard constraints

- No behavior change unless explicitly requested. A behavior-preserving edit keeps the exact-int/exact-uint behavior it found. Do not add metadata the path did not already keep. The create/restore rule in coding-standards applies to a new builtin or an intentional behavior change.
- No user-visible error message drift unless explicitly requested.
- C++ cleanups follow cpp-class-design. Move one cluster off `MathParser` at a time (errors, then static scalar/exact helpers, then raw-result formatting, then lexer helpers). Leave Basic’s procedure layout as it is. A file split that keeps every function as a `MathParser` method is not the cleanup.
- No UB in C++.
- Keep Basic/C++ parity when both sides exist (parity skill).
- Avoid extra allocations/copies on hot paths. Do not replace iterator-style walks with eager flattening unless semantics require it.
- String constants: `FB_STR_*` / `STR_*` (coding-standards flow).
- If a touched operator/builtin path changes behavior, decide whether `inf` / `-inf` / `nan` are accepted or rejected (common math/calculator expectations), even when non-finites were not the goal of the edit; keep Basic/C++ parity; lock with tests (smoke-tests flow).

## Refactor workflow

1. Read protect-workspace before the first edit. That skill skips the copy when the tree is clean.
2. Inventory duplicates (impact / risk / testability).
3. Choose helper strategy (reuse → extend → narrow new helper) per coding-standards. In C++, the new or moved helper follows cpp-class-design (session member only when it uses session state).
4. Preserve efficiency: single-pass walks, pre-count + one allocation, scratch-buffer reuse in C++, no extra hot-path temps.
5. Apply one logical cluster at a time. Between clusters, compile the side you touched when practical; run formatter, smoke, and C++ gates once at step 7. On compile failure use build-gates compile discipline (one hypothesis → one edit → one compile; roll back if no improvement).
6. Remove dead code only when unused/unreachable/superseded is confirmed; otherwise keep it and list it in the report as a candidate.
7. Mirror via parity skill, then run the required build-gates once for the final diff (sequential; Basic before C++ when both apply). That run is the parity skill's gate step, not a second pass.

## Dead/unused code criteria

Removable only if:

- No references/call sites in the repo and not part of the required external API, or
- Provably unreachable under enclosing guards, or
- Fully superseded helper with no remaining use.

Record a short justification per removal.

## Validation gates (mandatory)

Run relevant gates from `internal-mathparser-build-gates`. All required gates must pass before completion.

## Completion report format

Report: files changed; duplicates eliminated; helper reuse/extraction; dead code removed + reason; dead-code candidates kept (and why); efficiency notes (why no slowdown); Basic/C++ test outcomes.
