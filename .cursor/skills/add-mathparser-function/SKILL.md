---
name: add-mathparser-function
description: Add a new builtin math function to AkelPad Smart Math end-to-end. Use when the user asks to add/implement/register a function in MathParser, extend function syntax hints, add smoke tests, or update USAGE_AND_SYNTAX documentation with consistent style and logic.
---

# Add MathParser Function

## Purpose

Implement a new builtin function consistently across parser code, signature hints, tests, and docs.

## When To Use

Use this skill when a request includes phrases like:
- add new function
- add builtin function
- implement function in MathParser
- register function signature
- add parser tests and docs
- add function docs with same style/logic
- добавить новую функцию
- добавить сигнатуру/подсказку функции
- обновить тесты и документацию функции

## Inputs To Collect First

Before editing files, confirm or infer:
- Function name
- Function purpose
- Argument model:
  - fixed arity (exact number of args), or
  - variadic (minimum + optional extra args)
- Argument type behavior:
  - scalar-only, or
  - scalar/array support per argument
- Error behavior and edge cases (invalid args, empty arrays, divide by zero, etc.)

If requirements are ambiguous, ask concise clarifying questions before coding.

## Files To Update

1. `MathParser.bas`
2. `SmokeTest_MathParser.bas`
3. `USAGE_AND_SYNTAX.md`

## Required Workflow

Follow all steps in order.

### 1) Implement Function In `MathParser.bas`

- Find existing builtin-function dispatch and related helper patterns.
- Add the new function implementation following established style in this file.
- Implement argument validation for arity and type/support rules.
- If the function supports arrays, preserve project conventions for:
  - broadcasting/scalar-vs-array behavior,
  - size compatibility checks,
  - return shape semantics.
- If variadic, validate minimum argument count and process extra args deterministically.
- Reuse existing helpers when possible; avoid introducing redundant utility code.

### 2) Add Signature Hint In `TryGetBuiltinSignatureHint`

- In `MathParser.bas`, locate `TryGetBuiltinSignatureHint`.
- Add or update the case for the new function name.
- Ensure hint text matches actual implementation:
  - function name spelling/casing convention,
  - argument count (fixed/variadic),
  - argument meaning and optional arguments.
- Keep formatting consistent with neighboring hints.

### 3) Add Tests In `SmokeTest_MathParser.bas`

- Add focused tests for normal behavior.
- Add edge/negative tests for invalid arity or invalid argument types.
- Add array/scalar combination tests when array support is expected.
- Add variadic tests (minimum args + multiple extra args) when applicable.
- Follow existing test naming and assertion style.

Minimum recommended coverage:
- one happy-path scalar case,
- one boundary or edge case,
- one failure case,
- one array-related case (if arrays supported).

### 4) Build And Run Smoke Tests

- After updating `SmokeTest_MathParser.bas`, build the updated smoke-test executable.
- Run smoke tests via `RunSmokeTests.bat`.
- Treat smoke-test failures as blockers: investigate, fix, rebuild, and rerun until passing.
- If the batch script is unavailable or fails due to environment/toolchain issues, report the exact blocker and include the last relevant output.

### 5) Update `USAGE_AND_SYNTAX.md`

- Add or update the function in the appropriate section.
- First scan nearby sections in `USAGE_AND_SYNTAX.md` and mirror their structure.
- Document:
  - purpose/description,
  - signature syntax,
  - each argument and constraints,
  - return value behavior (including arrays/variadic semantics if relevant).
- Add at least 2-3 examples:
  - basic scalar example,
  - edge/interesting case,
  - array example when supported.
- Keep terminology, tone, wording density, and explanation logic consistent with existing document sections.
- Do not introduce a new writing style for one function; this file should read as if written by one author.

## Validation Checklist

Before finishing, verify:
- Implementation, hint, tests, and docs are all updated.
- Updated smoke tests were built and executed via `RunSmokeTests.bat`.
- Signature hint and docs match real behavior exactly.
- Tests cover success + failure paths relevant to the function contract.
- `USAGE_AND_SYNTAX.md` changes match neighboring sections in style and reasoning flow.
- No unrelated behavior was changed.

## Response Format For Completion

When done, report:
- files changed,
- concise behavior summary,
- test coverage added,
- final `RunSmokeTests.bat` pass/fail summary line,
- any assumptions made due to missing requirements.
