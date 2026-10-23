---
name: internal-mathparser-basic-cpp-parity
description: >-
  Internal Basic↔C++ MathParser porting and reflection rules.
  Not a user entry point — load only when referenced by add-mathparser-function
  or parser-reusability-cleanup.
disable-model-invocation: true
---

# Internal: Basic/C++ Parity

Load when Basic or C++ parser/test sources change and mirroring may be required.

## When C++ porting applies

Required only if both `cpp/` and `cpp/MathParser.cpp` exist. If `cpp/MathParser.cpp` is missing, skip reflection and note that in the final report.

All C++ artifacts (sources, test batches, tools) stay under `cpp/`.

## Porting rules

- Basic parser ↔ C++ parser: port in **both** directions when either side changes.
- Basic tests ↔ C++ tests: mirror behavior expectations and cases in each language’s own harness.
- Applies to fixes, refactors, cleanup, hardening, and behavior-preserving rewrites that can still affect edges.
- Preserve intent/meaning, not only syntax translation.
- **No reference other project rule / separate projects:** implement equivalent logic in the other language (mirroring); do not call or depend on the other language’s runtime, binaries, or test harness.
- **Independence requirement (no shared test sources):** C++ tests must build and run without `SmokeTest_MathParser.bas` or any Basic test source. Basic tests must build and run without C++ sources or binaries. If a convenience helper reads the other side’s test file, it is optional: missing Basic sources must not fail the C++ suite, and missing C++ binaries must not fail Basic smoke tests.
- **Strong no to undefined behavior / no UB:** never introduce UB in C++ or Basic; rewrite any potential UB to a defined portable form before finishing.

## Structure may diverge

C++ may move functions off `MathParser` onto value, result, AST, and `EvalContext` types, or into `smartmath_internal`, per `.cursor/skills/add-mathparser-function/flows/cpp-class-design.md`. Basic stays a procedural module.

That split is a **no-op** on the Basic side when behavior, error text, and exact-int metadata are unchanged. Say so in the reflection note. Do not add Basic types to mirror the C++ layout. A behavior or error-text change is still mirrored both ways.

## Reflection gate

Whenever parser/tests change in either language, for each affected item record either:

- **Mirrored change** — equivalent update on the other side, or
- **No-op with justification** — other side already has *provably* equivalent behavior (not OK if behavior would be missing/wrong). Prefer adding/adjusting regression tests to prove parity. When those tests set expectations, follow `.cursor/skills/add-mathparser-function/flows/smoke-tests.md` (do not seed `expected` from live parser output).

If gates already ran for the pre-reflection diff, rerun **only** the gates required for files the reflection changed. Do not rerun gates for files that did not change. If gates have not run yet, run the gates required for the final diff. Use `.cursor/skills/internal-mathparser-build-gates/SKILL.md` (sequential; Basic before C++ when both apply). Do not restate that skill’s inventories here.

Parity mismatch, build failure, or test failure is a blocker: fix, rebuild, rerun until required sides pass.
