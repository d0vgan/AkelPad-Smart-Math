---
name: add-mathparser-function
description: >-
  Add a new builtin math function or builtin constant to AkelPad Smart Math
  end-to-end. Use when the user asks to add/implement/register a function or
  constant in MathParser, extend function syntax hints, add or review smoke
  tests (expected values from Python/docs, not current parser output;
  inverse-operation check when Python principal branch is wrong), run formatter
  and clipboard copy-normalization regression tests after Basic source edits,
  update reserved-name checks for constants, update USAGE_AND_SYNTAX
  documentation with consistent style, ASCII-friendly typography, and logic,
  work on the parser-wide complex-number support flag (default off; gated
  complex behavior and isolated complex tests), or mirror operator/function
  logic between real-only and complex-enabled paths. Progressive details live
  in flows/ and internal-mathparser-* skills — read those only when the
  matching flow is active.
---

# Add MathParser Function or Builtin Constant

## Purpose

Implement a new builtin function or builtin constant consistently across parser code, signature hints (functions only), reserved-name rules (constants), tests, and docs. Basic and C++ must stay mirrored when both exist.

## Agent loading rules

- **Do not** read every linked file at the start.
- Read a file only when the matching step/branch is active.
- Prefer the full repo-relative path when calling `Read` (paths below are from the workspace root).
- Internal skills (`internal-mathparser-*`) are dependencies, not alternate entry points.

## When To Use

Trigger phrases include:

- add new function / add builtin function / implement function in MathParser
- register function signature / add parser tests and docs / add function docs with same style/logic
- add builtin constant / reserved name (e.g. alongside `pi`, `e`)
- добавить новую функцию / добавить сигнатуру/подсказку функции / обновить тесты и документацию функции

## Inputs To Collect First

Confirm or infer before coding:

- Name (function or constant) and purpose
- Functions only:
  - argument model: fixed arity, or variadic (minimum + optional extras)
  - argument types: scalar-only, or scalar/array per argument
  - error/edge behavior (invalid args, empty arrays, divide by zero, etc.)

Ask concise clarifying questions if ambiguous.

## Classify Then Load

| If the task… | Read now |
|---|---|
| Edits any MathParser/SmartMath/cpp sources | `.cursor/skills/internal-mathparser-protect-workspace/SKILL.md` **before first edit** |
| Adds/changes a builtin **function** (or operator registration) | `.cursor/skills/add-mathparser-function/flows/implement-function.md` |
| Adds a builtin **constant** | `.cursor/skills/add-mathparser-function/flows/implement-constant.md` |
| Touches complex flag / Cartesian builtins / real↔complex paths | `.cursor/skills/add-mathparser-function/flows/complex-support.md` |
| Authors or reviews smoke/parity **expectations** | `.cursor/skills/add-mathparser-function/flows/smoke-tests.md` |
| Edits `USAGE_AND_SYNTAX.md` | `.cursor/skills/add-mathparser-function/flows/usage-docs.md` |
| Edits Basic/C++ parser **implementation** | `.cursor/skills/add-mathparser-function/flows/coding-standards.md` |
| Changes Basic or C++ parser/tests (mirroring) | `.cursor/skills/internal-mathparser-basic-cpp-parity/SKILL.md` |
| Is about to compile/run gates, or must decide which gates apply | `.cursor/skills/internal-mathparser-build-gates/SKILL.md` |

## Required Workflow

Follow in order. For a **new or changed function/constant**, steps 2–6 are mandatory (not optional “if you feel like it”). Skip a step only when its trigger truly does not apply (e.g. docs-only → skip implement; gates still follow build-gates inventories).

1. **Protect** — read protect-workspace **before the first edit** whenever any target path may be dirty.
2. **Implement** — function and/or constant flow; always read coding-standards with any parser code edit; complex-support if that branch applies; parity skill when `cpp/MathParser.cpp` exists and parser/tests change.
3. **Tests** — **required** when adding/changing a function or constant, or when reviewing expectations: read smoke-tests (plus complex-support for isolated complex suites) and add/update mirrored C++ cases when C++ exists.
4. **Docs** — **required** when adding/changing a function or constant (or when the task is docs-only): read usage-docs and update `USAGE_AND_SYNTAX.md`.
5. **Gates** — **required** before finishing any source-affecting change: read build-gates; run every gate that skill’s inventories require for the final diff, sequentially, Basic before C++ when both apply.
6. **Reflect** — **required** if either language’s parser or tests changed: record mirrored versus no-op (parity skill). Rerun gates only for files the reflection changed after the step 5 run, and only the gates build-gates requires for those files.

## Validation Checklist

- Touched branches are consistent (implementation, hints, tests, docs).
- Required gates from build-gates ran; Basic passed before any required C++.
- Parity complete, or skipped with missing-`cpp` note.
- `FunctionNames`, `OperatorNames`, and `EnsureConstNames` stay the only name tables; new spellings go there and nowhere else.
- Complex work gated + isolated suites (complex-support flow).
- Expected values from docs/Python/inverse checks, not live parser output (smoke-tests flow).
- Integer metadata / helpers / string constants follow the exact-int section in coding-standards (`MAX_MAGNITUDE`). Do not restate that section’s ranges here.
- No unrelated behavior changes; C++ artifacts under `cpp/` only.

## Response Format For Completion

Report: files changed; concise behavior summary; test coverage added; when those gates ran, one pass/fail line each for `RunSmokeTests.bat`, `RunFormatterTests.bat` / `FormatterRegressionTests.exe`, `RunCopyRegressionTests.bat` / `CopyRegressionTests.exe`, and `cpp/BuildTests_vc2022_x64.bat` / `cpp/Tests_MathParser.exe`; assumptions from missing requirements.
