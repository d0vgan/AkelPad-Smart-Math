---
name: internal-mathparser-build-gates
description: >-
  Internal MathParser build/test gate rules (sequential Basic then C++, compile
  error discipline, change-detection inventories). Not a user entry point —
  load only when referenced by add-mathparser-function or
  parser-reusability-cleanup.
disable-model-invocation: true
---

# Internal: MathParser Build And Test Gates

Load when deciding which gates apply, or immediately before any compile/test run.

## Source inventories (single source of truth)

**Basic implementation sources** (trigger `Compile.bat` and formatter/copy regression):

- `MathParser.bas`, `SmartMath.bas`, `SmartMath_About.bas`, `SmartMath_Config.bas`
- `SmartMath_Format.bas`, `SmartMath_CopyNormalize.bas`, `SmartMath_Globals.bi`, `SmartMath_Menu.bas`
- plus any other Basic implementation/source modules if present

**Formatter / copy test sources** (also trigger formatter/copy regression):

- `FormatterRegressionTests.bas`, `FormatterTest_Globals.bas`, `CopyRegressionTests.bas`

**Basic smoke triggers** (`RunSmokeTests.bat`):

- `SmokeTest_MathParser.bas` (or other Basic test modules), **or**
- `MathParser.bas` changed, **or** (precaution) `SmartMath.bas` / `SmartMath_Format.bas` changed

**C++ triggers** (`cpp/BuildTests_vc2022_x64.bat` then `cpp/Tests_MathParser.exe`):

- `cpp/MathParser.cpp`, `cpp/MathParser.hpp`, `cpp/Tests_MathParser.cpp`
- plus any other C++ parser/test sources or headers under `cpp/`

**Non-triggers alone:** `USAGE_AND_SYNTAX.md`, `.cursor/` skill, rule, and process-doc edits, unrelated notes.

When unsure whether a file affects runtime behavior, treat it as a trigger.

## Compile and build error discipline (Required)

On any build/compile failure (`Compile.bat`, `Compile32.bat`, `Compile64.bat`, formatter/copy batches, `cpp/BuildTests_vc2022_x64.bat`, related toolchains):

- **Toolchain stop:** if the batch is missing or the failure is the environment (for example FreeBASIC path or MSVC toolset), stop immediately. Report the blocker and the last output. Do not edit sources to work around it, and do not spend the 3-iteration loop on it.
- Assume the toolchain is right; “compiler bug” is last resort after the checklist.
- Fix the **first meaningful error**; ignore cascading diagnostics until it is gone.
- Smallest direct fix only; no drive-by refactors.
- Keep each attempt small and reversible: one hypothesis → one edit → one compile/build. If diagnostics do not improve, **roll back** that edit before the next hypothesis.
- Checklist before blaming the compiler, in order:
  1. Touched files saved, and they are the files the build compiles
  2. Includes/modules (`Compile.bat` ↔ `Compile32.bat`/`Compile64.bat` parity, C++ headers)
  3. Types and signatures (Basic `byref`/`byval`, C++ const/member/static, arity)
  4. Generated or copied code (stale `.obj`/`.exe`, wrong output path)
  5. Arch/flags (`-arch`, MSVC config, bitness)
  6. Clean rebuild (incremental artifacts)
  7. Toolchain versions (FreeBASIC path, MSVC toolset)
  8. API/parity drift (renamed helpers, moved declarations, Basic vs C++)
- **Hard loop limit:** after **3** failed fix-compile iterations on the same primary error, stop, summarize facts (first error text, files changed, hypotheses tried, rollback status), and ask for human review — do not invent workarounds or disable checks.

## Test and guard execution order (Required)

- Always run sequentially — **never in parallel** (no parallel shell/tool calls for compile+run steps).
- Finish one gate completely (compile OK, then run OK, exit 0) before starting the next.
- **Exception:** if `Compile.bat` failed, still run `RunFormatterTests.bat` then `RunCopyRegressionTests.bat` so those regressions stay visible. After that compile is fixed, rerun `Compile.bat` and both regression batches.
- When both Basic and C++ gates are required, complete **all** required Basic gates first, then C++. A failed compile does not allow starting C++:
  1. `Compile.bat` (if required)
  2. `RunFormatterTests.bat` then `RunCopyRegressionTests.bat` (if required; never together)
  3. `RunSmokeTests.bat` (if required)
  4. `cpp/BuildTests_vc2022_x64.bat` then `cpp/Tests_MathParser.exe`
- Do not start the C++ build while a Basic gate is still running or has failed.

## Gate: Compile (`Compile.bat`)

- If you edit `Compile.bat`’s module list, keep `Compile32.bat` and `Compile64.bat` in lockstep (same sources, same order; only `-arch` / `-x` / arch flags may differ).
- Run only when a **Basic implementation source** changed; otherwise skip.
- On failure: toolchain stop above before any source edit; otherwise compile-error discipline until compile succeeds.

## Gate: Formatter + copy regression

Run **both** from repo root when a **Basic implementation source** or a **formatter/copy test source** changed; otherwise skip.

- `RunFormatterTests.bat` → `FormatterRegressionTests.exe` (globals + `SmartMath_Format.bas`).
- Then `RunCopyRegressionTests.bat` → `CopyRegressionTests.exe` (globals + `SmartMath_CopyNormalize.bas`).
- Independent of DLL smoke: still run these if `Compile.bat` failed, so regressions stay visible; after fixing compile, rerun compile **and** both regressions.
- On failure: toolchain stop above before any source edit. Otherwise follow compile-error discipline and fix format/copy sources or tests until exit 0.

## Gate: Basic smoke (`RunSmokeTests.bat`)

- Run only for **Basic smoke triggers** above; otherwise skip.
- Must pass before any required C++ gate starts.
- Build the smoke executable after Basic test edits, then run `RunSmokeTests.bat`.
- Failures are blockers: toolchain stop above before any source edit. Otherwise fix, rebuild, and rerun until pass.

## Gate: C++ build/test

- Run only for **C++ triggers**; otherwise skip entirely.
- Prerequisite: every required Basic gate already passed.
- Build with `cpp/BuildTests_vc2022_x64.bat`; on failure, toolchain stop above before any source edit, otherwise compile-error discipline until the build succeeds.
- Then run `cpp/Tests_MathParser.exe`; on failure: analyze → fix → rebuild → rerun until pass.
