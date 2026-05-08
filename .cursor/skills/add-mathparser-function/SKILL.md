---
name: add-mathparser-function
description: Add a new builtin math function or builtin constant to AkelPad Smart Math end-to-end. Use when the user asks to add/implement/register a function or constant in MathParser, extend function syntax hints, add smoke tests, run formatter and clipboard copy-normalization regression tests after Basic source edits, update reserved-name checks for constants, or update USAGE_AND_SYNTAX documentation with consistent style and logic.
---

# Add MathParser Function or Builtin Constant

## Purpose

Implement a new builtin function or builtin constant consistently across parser code, signature hints (functions only), reserved-name rules (constants), tests, and docs.

This skill enforces strict cross-language *porting* (mirroring) between the Basic implementation and the C++ reference implementation.

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

For any **new operator** or **new builtin function**, explicitly decide whether non-finite values (`inf`, `-inf`, `nan`) should be accepted or rejected:
- use common sense, standard math expectations, and typical calculator behavior,
- keep Basic/C++ parity for this decision,
- add/update tests to lock the chosen behavior and associated error text.

## Files To Update

1. `MathParser.bas`
2. `SmokeTest_MathParser.bas`
3. `USAGE_AND_SYNTAX.md`

For **builtin constants**, also keep the standalone C++ reference parser in sync when the repo maintains it: `cpp/MathParser.cpp` (constant registration and any reserved-name logic there).

### C++ Location Rule

- All C++-related activities and artifacts must stay under the `cpp` folder.
- When adding C++ scripts/tools (for example build/test batch files), place them under `cpp` (not next to `.bas` files).

### Basic/C++ Parity Rule

- Whenever **Basic parser code** is updated, the changes must be **ported to C++ parser code**.
- Whenever **C++ parser code** is updated, the changes must be **ported to Basic parser code**.
- Whenever **Basic tests** are updated, the equivalent behavior expectations must be **ported to C++ parser code** (and the test cases must also be mirrored into C++ tests for parity).
- Whenever **C++ tests** are updated, the equivalent behavior expectations must be **ported to Basic parser code** (and the test cases must also be mirrored into Basic tests for parity).
- Applies to all change types (bug fixes, refactors, cleanup, safety hardening, behavior-preserving rewrites that can still affect edge behavior).
- Porting must preserve the original intent/meaning (not only syntax translation).
- **No reference other project rule:** Basic and C++ are treated as separate projects. Porting means implementing the equivalent logic in the other language (mirroring), not delegating to or depending on the other language’s runtime, build artifacts, or test harness.
- **Independence requirement (no shared test sources):**
  - C++ test code must not require `SmokeTest_MathParser.bas` (or any Basic test source) to exist in order to build/run.
  - Basic test code must not require C++ test executables/sources to exist in order to build/run.
  - Any parity coverage needed on both sides must be added by **mirroring** tests into each language’s own test source, not by importing/execute-orchestrating the other side’s tests.
- If the repo currently has convenience helpers that read the other side’s test file, treat them as optional only:
  - missing test sources must never cause C++ to fail the whole suite.
  - missing C++ binaries must never make Basic smoke tests fail.
- **Strong no to undefined behavior:** never introduce UB in either C++ or Basic code. Treat any potential UB pattern as a blocker and rewrite it to a defined, portable form before finishing.
- C++ porting is required only when both are true:
  - `cpp` folder exists, and
  - `cpp/MathParser.cpp` exists.
- If `cpp/MathParser.cpp` is missing, skip Basic->C++ reflection and note that assumption in the final report.

### Global Helper Reuse And Optimization Rule

Apply this rule for **any source-code change** (feature/fix/refactor/cleanup/optimization):

- Always avoid code duplication; prefer shared helpers.
- Before introducing a new helper, search for existing helpers that already cover or nearly cover the needed behavior.
- If an existing helper is close but not exact, tune/extend that helper and reuse it in both old and new call sites.
- While tuning existing helpers, keep them maximally optimized for their hot-path usage.
- If no existing helper can be tuned without harming clarity/behavior/performance, introduce a new helper instead.
- When adding a new helper, keep scope minimal and avoid overlapping responsibilities with existing helpers.
- Prefer reusing existing local variables/state before introducing new temporary variables; add a new variable only when it is clearly necessary for correctness, readability, or performance.
- Preserve consistent block indentation when refactoring/optimizing; changed code must keep project indentation style and cleanly aligned nested blocks.

### Integer Metadata Preservation Rule (Required)

Apply this rule for parser/runtime logic in both Basic and C++:

- Treat exact signed/unsigned integer metadata as first-class state (`exactInt64` / `exactUInt64` or language-equivalent fields).
- Whenever signed/unsigned int64 metadata is available in value context, operations must preserve and propagate it unless the operation is inherently non-integer by semantics.
- For scalar/array flattening, reshaping, sorting, reversing, deduping, formatting, unpacking, and similar structure-only transforms, do not drop integer metadata by converting through raw `double`/`Double` buffers.
- Prefer scalar-value containers/walkers that carry metadata (`ScalarValue`-like) over float-only containers in context-preserving paths.
- For float-derived restoration paths, signed/unsigned int64 restoration must be strict and policy-based:
  - restore only when exact representability is guaranteed by project policy,
  - reject/rest on overflow, fractional values, NaN/Inf, and out-of-policy ranges,
  - keep parity between Basic and C++ conversion boundaries and error behavior.
- If a path intentionally does not preserve integer metadata (for example transcendental math, variance/stddev, or other inherently floating operations), document/justify that choice in code review notes and protect it with tests.

### String Constants Naming Rule

Apply this rule for parser/runtime code in both Basic and C++:

- Any string literal longer than 1 character must be represented by a named string constant.
- One-character string literals may remain inline.
- Reuse existing named string constants when the same literal value is already present.
- If a new constant is needed, give it a human-readable semantic name (avoid numeric/opaque names like `STR_0001`).
- Keep naming style consistent with existing constants in each language (`STR_*` in C++, `FB_STR_*` in Basic).

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
- Follow the **Global Helper Reuse And Optimization Rule** above for all helper-level decisions.
- Follow the **Integer Metadata Preservation Rule (Required)** above for all numeric-value flow decisions.
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

### 3) Build Sources (`Compile.bat`, `Compile32.bat`, `Compile64.bat`)

- **`Compile.bat` parity rule:** Whenever you change **`Compile.bat`** (for example add/remove/reorder Basic modules on the `fbc` line), apply the **same** source list to **`Compile32.bat`** and **`Compile64.bat`**. Keep all three in lockstep: same `.bas` / `.bi` inputs in the same order; only the 32-bit and 64-bit batches may differ by `-arch`, `-x` output name, or other architecture-specific `fbc` flags—not by which plugin sources are compiled.
- Run `Compile.bat` only when **Basic parser source files** were changed.
  - Treat this Basic source set as build-triggering:
    - `MathParser.bas`
    - `SmartMath.bas`
    - `SmartMath_About.bas`
    - `SmartMath_Config.bas`
    - `SmartMath_Format.bas`
    - `SmartMath_CopyNormalize.bas`
    - `SmartMath_Globals.bi`
    - `SmartMath_Menu.bas`
  - Also include any additional Basic implementation/source modules if present.
  - If Basic parser source was **not** changed, skip `Compile.bat`.
- If compilation fails, treat it as a blocker:
  - analyze build errors,
  - fix sources,
  - rerun `Compile.bat`.
- Repeat analyze/fix/rerun loop until compilation succeeds.
- If compilation cannot succeed due to environment/toolchain issues, report the exact blocker and include the last relevant output.

### 3.1) Formatter and copy regression tests (`RunFormatterTests.bat` + `RunCopyRegressionTests.bat`)

Run **both** batches from the repo root whenever **Basic implementation source** from the step 3 / `Compile.bat` trigger set changed, **or** whenever **either** formatter **or** copy test sources changed:

- Formatter / display: `FormatterRegressionTests.bas`, `FormatterTest_Globals.bas`
- Clipboard double-click normalization: `CopyRegressionTests.bas` (reuses `FormatterTest_Globals.bas` + `SmartMath_CopyNormalize.bas`)

**Formatter (`RunFormatterTests.bat`):**

- Compiles `FormatterTest_Globals.bas` + `FormatterRegressionTests.bas` + `SmartMath_Format.bas` → `FormatterRegressionTests.exe`.
- If compilation or the executable fails, treat as a blocker; fix `SmartMath_Format.bas` / globals / tests; rerun until exit code 0.

**Copy normalization (`RunCopyRegressionTests.bat`):**

- Compiles `FormatterTest_Globals.bas` + `CopyRegressionTests.bas` + `SmartMath_CopyNormalize.bas` → `CopyRegressionTests.exe`.
- If compilation or the executable fails, treat as a blocker; fix `SmartMath_CopyNormalize.bas` / globals / tests; rerun until exit code 0.

**Shared rules:**

- These gates are **independent** of the DLL smoke build: run them even if `Compile.bat` failed so regressions stay visible—after fixing `Compile.bat` blockers, rerun `Compile.bat` and **both** regression batches.
- If a batch is unavailable or fails due to environment/toolchain issues (for example FreeBASIC path), report the exact blocker and include the last relevant output.
- If none of the trigger files above changed (docs-only / skills-only / C++-only with no Basic edits), skip this entire step 3.1.

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

- Run Basic smoke-test build/run only when **Basic test source files** were changed.
  - Treat test source as files like `SmokeTest_MathParser.bas` (and any other Basic test files if present).
- Also run Basic smoke-test build/run when `MathParser.bas` changed (primary parser-change trigger).
  - Also run Basic smoke-test build/run as a precautionary regression gate when either of these files changed:
    - `SmartMath.bas`
    - `SmartMath_Format.bas`
  - If none of these changed (Basic test source, `MathParser.bas`, `SmartMath.bas`, `SmartMath_Format.bas`), skip compiling tests and skip `RunSmokeTests.bat`.
  - Formatter and copy regression tests (**step 3.1**, `RunFormatterTests.bat` and `RunCopyRegressionTests.bat`) still apply whenever Basic implementation sources or formatter/copy test sources changed, even if this smoke-test skip condition is true (for example only `SmartMath_Config.bas` changed: run both regression batches, but smoke tests may be skipped per bullets above).
- After updating Basic tests, build the updated smoke-test executable.
- Then run smoke tests via `RunSmokeTests.bat`.
- Treat smoke-test failures as blockers: investigate, fix, rebuild, and rerun until passing.
- If the batch script is unavailable or fails due to environment/toolchain issues, report the exact blocker and include the last relevant output.

### 5.1) C++ Build/Test Gate (for any C++ code changes)

Apply this step only when **C++ parser or C++ test source files** are changed (for example `cpp/MathParser.cpp`, `cpp/MathParser.hpp`, `cpp/MathParserTests.cpp`):

- If neither C++ parser source nor C++ test source changed, skip this entire C++ build/test gate (do not run `cpp/BuildTests_vc2022_x64.bat`, do not run `cpp/MathParserTests.exe`).

- Run `cpp/BuildTests_vc2022_x64.bat`.
- If build fails:
  - treat as blocker,
  - analyze compiler/linker errors,
  - fix C++ code,
  - rerun `cpp/BuildTests_vc2022_x64.bat`,
  - repeat until build succeeds.
- Once build succeeds, run produced test binary: `cpp/MathParserTests.exe`.
- If tests fail:
  - analyze failing test output,
  - identify root cause,
  - fix C++ code/tests as appropriate,
  - rebuild via `cpp/BuildTests_vc2022_x64.bat`,
  - rerun `cpp/MathParserTests.exe`,
  - repeat until tests pass.
- If build/test cannot complete due to environment/toolchain issues, report the exact blocker and include the last relevant output.

### 5.2) Cross-Language Reflection Gate (Basic <-> C++)

Use this gate whenever parser/tests are changed in either language:

Port according to the **Basic/C++ Parity Rule** above (including mirroring parser behavior and test cases in both directions).

For each affected item, produce one of two outcomes:

- **Mirrored change**: equivalent implementation/test update was applied on the other side, or
- **No-op with justification**: the other side already has *provably equivalent behavior*, so porting is unnecessary. (Not acceptable when behavior would be missing/incorrect.)

If claiming **No-op with justification**, add/adjust regression tests to prove behavior parity where practical.
- After reflection, run only the checks relevant to changed source categories:
  - If Basic parser source changed: run `Compile.bat` until passing.
  - If Basic implementation source changed (step 3 trigger set) or formatter/copy test sources changed: run `RunFormatterTests.bat` and `RunCopyRegressionTests.bat` until passing (step 3.1).
  - If Basic test source changed: run Basic smoke-test build/run (`RunSmokeTests.bat`) until passing.
  - If C++ parser or C++ test source changed: run `cpp/BuildTests_vc2022_x64.bat`, then `cpp/MathParserTests.exe`, until passing.
- Treat any parity mismatch, build failure, or test failure as blocker; analyze root cause, fix, rebuild, rerun, and repeat until all required sides pass.

### 5.3) Change Detection Examples (What Counts As Source Changes)

Use these examples when deciding whether a gate must run:

- **Basic parser source changed** (run `Compile.bat`):
  - `MathParser.bas`
  - `SmartMath.bas`
  - `SmartMath_About.bas`
  - `SmartMath_Config.bas`
  - `SmartMath_Format.bas`
  - `SmartMath_CopyNormalize.bas`
  - `SmartMath_Globals.bi`
  - `SmartMath_Menu.bas`
  - any additional Basic implementation/source modules if present.

- **Basic test source changed** (run Basic smoke-test build/run via `RunSmokeTests.bat`):
  - `SmokeTest_MathParser.bas`
  - any additional Basic test source modules if present.
  - additionally, run when `MathParser.bas` changed (primary parser-change trigger).
  - additionally, run as precaution when `SmartMath.bas` or `SmartMath_Format.bas` changed.

- **Basic implementation or formatter/copy test source changed** (run **`RunFormatterTests.bat`** and **`RunCopyRegressionTests.bat`** — step 3.1):
  - same file set as **Basic parser source changed** / `Compile.bat` (see list above), and
  - `FormatterRegressionTests.bas`, `FormatterTest_Globals.bas`, `CopyRegressionTests.bas`.

- **C++ parser or C++ test source changed** (run `cpp/BuildTests_vc2022_x64.bat` + `cpp/MathParserTests.exe`):
  - `cpp/MathParser.cpp`
  - `cpp/MathParser.hpp`
  - `cpp/MathParserTests.cpp`
  - any additional C++ parser/test source or headers under `cpp`.

- **Non-source-only edits** (do not trigger source gates by themselves):
  - docs-only changes like `USAGE_AND_SYNTAX.md`,
  - skill/rule/process docs changes under `.cursor/`,
  - unrelated notes/readme updates.

When in doubt, classify conservatively: if a file plausibly affects parser/test runtime behavior, treat it as source and run the corresponding gate.

### 6) Update `USAGE_AND_SYNTAX.md`

- Add or update the function in the appropriate section.
- Update the **"Quick index (alphabetical)"** table at the beginning of **"Built-in Functions"**:
  - keep function names sorted alphabetically,
  - keep aliases on the same row as the canonical function (for example `asin/arcsin(value)`),
  - keep category labels consistent with nearby rows.
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
- Run a quick typo pass on changed doc lines before finishing (especially split words from accidental edits, e.g. `implemen ted`).

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

Same as for functions: `Compile.bat`, `RunFormatterTests.bat` and `RunCopyRegressionTests.bat` when Basic implementation or formatter/copy test sources changed (step 3.1), then `RunSmokeTests.bat`, until clean.

## Validation Checklist

Before finishing, verify:
- Implementation, signature hints, tests, and `USAGE_AND_SYNTAX.md` are consistent with the final behavior.
- If `Compile.bat` was edited, `Compile32.bat` and `Compile64.bat` list the same Basic modules in the same order (step 3 parity rule).
- Required build/test gates ran based on what changed: `Compile.bat` (Basic parser), `RunFormatterTests.bat` and `RunCopyRegressionTests.bat` (Basic implementation or formatter/copy test sources — step 3.1), `RunSmokeTests.bat` (Basic tests or `MathParser.bas` and regression gates), and `cpp/BuildTests_vc2022_x64.bat` + `cpp/MathParserTests.exe` (C++ parser/tests).
- Cross-language porting/parity is complete for **all** relevant code/test change types: Basic <-> C++ implementations and tests are mirrored, with no mismatches (skip only allowed when `cpp/MathParser.cpp` is missing, and it must be explicitly noted).
- Helper reuse and string-constant naming rules were followed in both languages; `FunctionNames` / `OperatorNames` remain the single canonical sources.
- Safety/docs gates: avoid UB, block user-defined names colliding with built-ins/operators, USAGE quick index is correct, no doc typos/split words, and style/structure match surrounding sections.
- Tests cover both success and failure paths; if adding a new builtin constant, extend the Basic constant table + mirror reserved-name behavior into C++ (when present) and add/reflect constant-specific smoke tests + docs.
- Integer metadata preservation/restoration was verified in both languages:
  - context-preserving paths do not silently drop `exactInt64` / `exactUInt64`,
  - float-derived restoration follows strict exactness policy with matching Basic/C++ boundaries,
  - intentionally non-preserving math paths (if any) are justified and covered by tests.
- No unrelated behavior changes; any C++ artifacts touched live under `cpp` only.

## Response Format For Completion

When done, report:
- files changed,
- concise behavior summary,
- test coverage added,
- final `RunSmokeTests.bat` pass/fail summary line (when that gate ran),
- final step 3.1 pass/fail summary lines for `RunFormatterTests.bat` / `FormatterRegressionTests.exe` and `RunCopyRegressionTests.bat` / `CopyRegressionTests.exe` (when that step ran),
- any assumptions made due to missing requirements.
