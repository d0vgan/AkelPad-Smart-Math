---
name: mathparser-add-or-fix
description: >-
  Add or change AkelPad Smart Math parser behavior end-to-end in Basic and C++:
  new builtin functions, operators, or constants; user-defined functions and
  lambdas as one callable (a change, test, review, or fix of either surface
  covers the other and reuses their shared helpers); signature hints; reserved
  names; bug fixes that change results or errors; smoke/parity test
  expectations (from Python/docs, never from live parser output) and
  investigating failing tests; the complex-number support flag;
  USAGE_AND_SYNTAX documentation; and the build/test gates.
---

# Add or Fix MathParser Behavior

## Purpose

Implement a builtin function, operator, constant, or behavior fix consistently across parser code, signature hints (functions), reserved-name rules (constants), tests, and docs. Basic and C++ always stay mirrored.

User-defined functions and lambdas are two surfaces of the same callable. Analyzing, verifying, testing, correcting, optimizing, refactoring, or otherwise changing either surface does the same for the other, and reuses their shared code. A change on one surface can change the other.

For behavior-preserving refactors or dead-code removal, use `mathparser-refactor` instead.

Also triggered by: добавить новую функцию / добавить сигнатуру/подсказку функции / исправить ошибку парсера / обновить тесты и документацию / пользовательская функция / лямбда.

## Agent loading rules

- Do not read every linked file at the start. Read a file only when its row in the table below applies.
- Use the repo-relative paths below with `Read`.
- Internal skills (`internal-mathparser-*`) are dependencies, not entry points.
- This table is the only routing table; flows do not repeat it.

## Inputs To Collect First

- Name (function, operator, or constant) and purpose, or the reported defect and its reproduction
- Functions: arity (fixed or variadic minimum), scalar/array per argument, error/edge behavior (invalid args, empty arrays, divide by zero), and the feature it depends on, if any (complex, time, lambdas)
- User functions or lambdas: the body rule or the name rule, and which surfaces can express it (classic definition, lambda-style definition, anonymous `sortby` / `filter`). The other surfaces are in scope even when the request names only one.
- Operators and constants: the extra inputs listed at the top of their flow

Ask concise clarifying questions if ambiguous.

## Classify Then Load

| If the task… | Read now |
|---|---|
| Plans or implements parser behavior, or investigates results, errors, or limits | `.cursor/skills/mathparser-add-or-fix/flows/raise-concerns.md` |
| Edits any source file or script (parser, test, generated test data, `.bat`, `.py`); not docs | `.cursor/skills/internal-mathparser-protect-workspace/SKILL.md` **before first edit** (and for **stage checkpoints** on multi-stage work) |
| Adds/changes a builtin **function** or an **operator** | `.cursor/skills/mathparser-add-or-fix/flows/implement-function.md` |
| Analyzes, verifies, tests, corrects, optimizes, refactors, or changes a **user-defined function** or a **lambda** (either surface, including a shared body or parameter helper) | `.cursor/skills/mathparser-add-or-fix/flows/user-functions-and-lambdas.md` |
| Adds/changes a function or operator, or changes array / `()` results, errors, tests, or docs | `.cursor/skills/mathparser-add-or-fix/flows/empty-array-policy.md` |
| Adds a builtin **constant** | `.cursor/skills/mathparser-add-or-fix/flows/implement-constant.md` |
| Fixes a defect / changes existing results or errors | `.cursor/skills/mathparser-add-or-fix/flows/fix-behavior.md` |
| Edits Basic/C++ parser **implementation** | `.cursor/skills/mathparser-add-or-fix/flows/coding-standards.md` |
| Edits `cpp/MathParser.hpp` / `.cpp` shape, helpers, or builtin routing | `.cursor/skills/mathparser-add-or-fix/flows/cpp-class-design.md` |
| Touches complex flag / Cartesian builtins / real↔complex paths, or code under `#if SMARTMATH_*` | `.cursor/skills/mathparser-add-or-fix/flows/complex-support.md` |
| Authors or reviews smoke/parity **expectations**, or any test fails | `.cursor/skills/mathparser-add-or-fix/flows/smoke-tests.md` |
| Touches numeric edge cases, NaN/Inf per-function rules, trig snap, aggregation accuracy, float display digits, RNG detail, or shared scalar compare / unique hash | `.cursor/skills/mathparser-add-or-fix/flows/numeric-behavior.md` |
| Edits `USAGE_AND_SYNTAX.md` | `.cursor/skills/mathparser-add-or-fix/flows/usage-docs.md` |
| Changes Basic or C++ parser/tests (mirroring), or `cpp/calc.cpp` / `tools/calc.bas` | `.cursor/skills/internal-mathparser-basic-cpp-parity/SKILL.md` |
| Is about to compile/run gates, probe behavior, or decide which gates apply | `.cursor/skills/internal-mathparser-build-gates/SKILL.md` |

## Required Workflow

Follow in order. Skip a step only when its trigger does not apply.

1. **Concerns** — throughout planning and implementation, raise-concerns. A rejection, limit, or mathematical mismatch found in reasoning is raised with a proposed fix and before/after examples, and waited on before the plan or the edit treats it as settled.
2. **Protect** — before the first source/script edit. On multi-stage work (plan steps or judged self-sufficient stages), also take a **stage checkpoint** after each successful stage per protect-workspace "Stage checkpoints" — before the next stage starts — so later reverts do not wipe verified progress.
3. **Implement** — every table row that applies to the edit. After a self-sufficient implementation stage succeeds, checkpoint before tests/docs/further clusters when more stages remain.
4. **Tests** — for any new or changed function, operator, constant, or behavior, mirrored in C++. A user function or lambda change includes both surfaces (user-functions-and-lambdas flow). Checkpoint after tests when skills/docs/gates still follow as separate stages.
5. **Docs** — when **end-user** documented behavior is added or changes (usage-docs "Audience"). Technical edge cases and numeric limits go to numeric-behavior (and tests), not into USAGE function bullets. Skill/flow updates that are their own stage get a stage checkpoint of those files.
6. **Gates** — before finishing any change; build-gates decides which apply (a docs-only change that touches the Quick index still runs the docs index check). No checkpoint for a pure gate run; checkpoint before gate-driven fix edits if a prior stage was already complete.
7. **Reflect** — when either parser or its tests changed: parity skill reflection gate (it owns the gate-rerun rule).

## Validation Checklist

- Concerns found in reasoning were raised per raise-concerns, each with a proposed fix and before/after examples, and the user decided each one before it was treated as settled.
- Multi-stage work used protect-workspace stage checkpoints after each successful self-sufficient stage (not mid-feature, not excessively often).
- Required gates from build-gates ran; Basic passed before any required C++; no build printed a new compiler warning (build-gates "Warnings"), and the C++ analyze gate is clean when C++ changed.
- Parity complete (parity skill reflection gate).
- `FunctionNames`, `OperatorNames`, and `ConstNames` stay the only Basic name tables; C++ name lists follow implement-function / implement-constant.
- Complex work is gated and its tests are isolated (complex-support flow).
- Expected values come from references, not parser output; every mismatch was handled per smoke-tests "Handling a test mismatch".
- Integer metadata, helpers, string constants, and non-finite handling follow coding-standards; numeric edge rules follow numeric-behavior; USAGE stays end-user (usage-docs).
- New/changed source and test comments are ASCII only (coding-standards / smoke-tests); new/changed text in `USAGE_AND_SYNTAX.md` and `SmartMath-Eng.md` is ASCII only (usage-docs).
- Comparison / equality / ordering / dedupe paths use the shared compare helpers (and exact-int-aware unique hash); no site-local float `<`/`==` for scalars (numeric-behavior / coding-standards).
- Array and `()` results follow empty-array-policy; implementation, tests, and docs agree with it.
- User-function and lambda work covered both surfaces through the shared helpers (user-functions-and-lambdas flow).
- No unrelated behavior changes; C++ artifacts under `cpp/` only.
- C++ additions follow cpp-class-design; Basic structure is unchanged.

## Response Format For Completion

Report:

- files changed;
- concise behavior summary (when a user function or a lambda was in scope: both surfaces, and the shared helper that owns the rule);
- test coverage added, and any existing expectations corrected (with the reference that justified each correction);
- one pass/fail line for each gate that ran (gate names as in build-gates "Invocation"), plus any warnings found, whether each was fixed or already existed;
- concerns raised to the user, and the decision for each; or that none were identified
- remaining Basic/C++ or Python differences (noting which are allowed floating-point inaccuracy) and assumptions from missing requirements. A rejection or limit appears here only after the user has decided to keep it.
