---
name: add-mathparser-function
description: Add a new builtin math function or builtin constant to AkelPad Smart Math end-to-end. Use when the user asks to add/implement/register a function or constant in MathParser, extend function syntax hints, add smoke tests, update reserved-name checks for constants, or update USAGE_AND_SYNTAX documentation with consistent style and logic.
---

# Add MathParser Function or Builtin Constant

## Purpose

Implement a new builtin function or builtin constant consistently across parser code, signature hints (functions only), reserved-name rules (constants), tests, and docs.

## When To Use

Use this skill when a request includes phrases like:
- add new function
- add builtin function
- implement function in MathParser
- register function signature
- add parser tests and docs
- add function docs with same style/logic
- add builtin constant / reserved name (e.g. alongside `pi`, `e`)
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

For **builtin constants**, also keep the standalone C++ reference parser in sync when the repo maintains it: `cpp/MathParser.cpp` (constant registration and any reserved-name logic there).

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
- Maintain exactly one canonical `FunctionNames` array and one canonical `OperatorNames` array in parser code.
- Add the new built-in/operator name only in these canonical arrays with a named index (e.g. `FUNC_*`, `OP_*`).
- Wherever parser logic needs built-in/operator names (dispatch, hints, keyword matching, reserved-name checks), reference `FunctionNames[FUNC_*]` / `OperatorNames[OP_*]` (or helper wrappers over them), never hardcoded string literals.
- Update reserved-name guards so user-defined functions cannot use:
  - the new built-in function name (via `FunctionNames`),
  - any newly introduced operator keyword names (via `OperatorNames`).

### 2) Add Signature Hint In `TryGetBuiltinSignatureHint`

- In `MathParser.bas`, locate `TryGetBuiltinSignatureHint`.
- Add or update the case for the new function name.
- Ensure hint text matches actual implementation:
  - function name spelling/casing convention,
  - argument count (fixed/variadic),
  - argument meaning and optional arguments.
- Keep formatting consistent with neighboring hints.

### 3) Build Sources (`Compile.bat`)

- After implementation and signature-hint updates, run `Compile.bat`.
- If compilation fails, treat it as a blocker:
  - analyze build errors,
  - fix sources,
  - rerun `Compile.bat`.
- Repeat analyze/fix/rerun loop until compilation succeeds.
- If compilation cannot succeed due to environment/toolchain issues, report the exact blocker and include the last relevant output.

### 4) Add Tests In `SmokeTest_MathParser.bas`

- Add focused tests for normal behavior.
- Add edge/negative tests for invalid arity or invalid argument types.
- Add array/scalar combination tests when array support is expected.
- Add variadic tests (minimum args + multiple extra args) when applicable.
- Follow existing test naming and assertion style.
- Always include single-argument coverage when function accepts 1 argument or variadic arguments:
  - one normal single-argument case,
  - one single-argument edge case,
  - one single-argument overflow/range-limit case when numeric domain has limits.

Minimum recommended coverage:
- one happy-path scalar case,
- one boundary or edge case,
- one failure case,
- one array-related case (if arrays supported).
- one single-argument case (for 1-arg/variadic functions), plus single-arg edge and overflow checks when applicable.

### 5) Build And Run Smoke Tests

- After updating `SmokeTest_MathParser.bas`, build the updated smoke-test executable.
- Run smoke tests via `RunSmokeTests.bat`.
- Treat smoke-test failures as blockers: investigate, fix, rebuild, and rerun until passing.
- If the batch script is unavailable or fails due to environment/toolchain issues, report the exact blocker and include the last relevant output.

### 6) Update `USAGE_AND_SYNTAX.md`

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

## Adding a Builtin Constant (Reserved Names)

Use this branch of the workflow when introducing a new identifier that is parsed as a **constant** (like `pi` and `e`), not a function call.

### Canonical table in `MathParser.bas`

Builtin constants use the same pattern as `FunctionNames`:

- **`BuiltinConstId`** — enum with `CONST_*` entries and a sentinel `CONST__COUNT`.
- **`ConstNames(0 to CONST__COUNT - 1)`** — lowercase spellings filled in **`EnsureConstNames()`** (e.g. `ConstNames(CONST_PI) = "pi"`).
- **`TryGetConstant`** — resolves a name via `TryFindBuiltinConstId` / `ConstNames`, then a `select case` on `BuiltinConstId` assigns the numeric value.
- **`IsBuiltinConstantName`** — returns true when `TryFindBuiltinConstId` finds an index (reserved for assignment / UDF names / parameters).

When adding a constant: extend the enum, add one line in `EnsureConstNames`, add one `case` branch in `TryGetConstant`. Do not register the spelling only in `TryGetConstant` without `EnsureConstNames` — reserved-name checks would miss it.

### Code paths that rely on `IsBuiltinConstantName`

After updating the constant table, confirm nothing else needs the new name:

- Assignment targets and related errors already go through `IsBuiltinConstantName` (search the file for calls if the parser gains new binding forms).
- Do not add a second hardcoded list of constant spellings; keep **`EnsureConstNames`** as the single source for strings.

### C++ parity (`cpp/MathParser.cpp`)

Constants are registered (e.g. via `addConst`). When adding a constant:

- Register the same identifier and value semantics there.
- If the C++ layer adds or already has reserved-name checks for assignments / UDFs, extend that set to match `IsBuiltinConstantName` in Basic.

### Tests (`SmokeTest_MathParser.bas`)

Mirror existing coverage for `pi` / `e`:

- Assignment LHS rejected (`expectedErrContains` matching `reserved constant name`).
- Case-insensitive variant if behavior is case-insensitive.
- UDF parameter name and UDF function name rejected when they match the new constant.

### Documentation (`USAGE_AND_SYNTAX.md`)

Update **every** place that documents builtin constants and reserved names so the new constant is listed **consistently** with `pi` and `e`. At minimum, scan the file for:

- The **Built-in constants** list (bullet list of constant identifiers).
- Sections that explain **reserved** names, assignment restrictions, and UDF/parameter restrictions.
- Examples that say constants resolve **before** variables (extend or add an example if it helps, same tone as `(e=3)` style notes).

Match the existing document’s structure, terminology, and density; do not document the new constant in only one section while older constants are described in several.

### Build and smoke

Same as for functions: `Compile.bat`, then `RunSmokeTests.bat`, until clean.

## Validation Checklist

Before finishing, verify:
- Implementation, hint, tests, and docs are all updated.
- Sources were successfully built via `Compile.bat`.
- Updated smoke tests were built and executed via `RunSmokeTests.bat`.
- Signature hint and docs match real behavior exactly.
- Tests cover success + failure paths relevant to the function contract.
- User-defined function names are explicitly blocked from colliding with built-in function names and operator keywords (including the newly added names).
- For **new builtin constants**: `BuiltinConstId`, `EnsureConstNames`, and `TryGetConstant` are extended together; smoke tests cover assignment, UDF name, and parameter rejection; `USAGE_AND_SYNTAX.md` lists and explains the constant everywhere `pi`/`e` are described; C++ `addConst` (and any C++ reserved-name logic) matches if present in the repo.
- There is still one and only one canonical `FunctionNames` array and one and only one canonical `OperatorNames` array; new names were integrated by named index and reused everywhere relevant.
- `USAGE_AND_SYNTAX.md` changes match neighboring sections in style and reasoning flow.
- No unrelated behavior was changed.

## Response Format For Completion

When done, report:
- files changed,
- concise behavior summary,
- test coverage added,
- final `RunSmokeTests.bat` pass/fail summary line,
- any assumptions made due to missing requirements.
