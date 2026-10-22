# Implement Builtin Function

Load when adding or changing a **builtin function** (or an operator path that uses the same registration pattern).

## Required follow-on reads (do not skip for a new/changed function)

| Phase | Path |
|---|---|
| Before coding parser logic | `.cursor/skills/add-mathparser-function/flows/coding-standards.md` |
| Complex / real↔complex paths involved | `.cursor/skills/add-mathparser-function/flows/complex-support.md` |
| `cpp/MathParser.cpp` exists and parser changes | `.cursor/skills/internal-mathparser-basic-cpp-parity/SKILL.md` |
| After behavior is implemented — **tests** | `.cursor/skills/add-mathparser-function/flows/smoke-tests.md` |
| After behavior is settled — **docs** | `.cursor/skills/add-mathparser-function/flows/usage-docs.md` |
| Before finishing — **gates** | `.cursor/skills/internal-mathparser-build-gates/SKILL.md` |

## Implementation files

- `MathParser.bas` (required)
- C++ under `cpp/` when the reference parser exists (`cpp/MathParser.cpp`, `cpp/MathParser.hpp`, mirrored tests)
- Then `SmokeTest_MathParser.bas` / C++ tests and `USAGE_AND_SYNTAX.md` via the tests/docs flows above (still mandatory for a complete add/change)

## Non-finite values

For any **new operator** or **new builtin function**, decide whether `inf` / `-inf` / `nan` are accepted or rejected:

- use common sense, standard math, and typical calculator behavior;
- keep Basic/C++ parity;
- lock with tests (and error text when rejecting).

## 1) Implement in `MathParser.bas`

- Follow existing builtin dispatch and helper patterns.
- Validate arity and type/support rules.
- If arrays are supported: preserve broadcasting, size checks, and return-shape conventions.
- If variadic: enforce minimum arity; process extra args deterministically.
- Follow coding-standards for helpers, integer metadata, and string constants, including the exact-int section (`MAX_MAGNITUDE`). Do not restate that section’s ranges here.
- Follow complex-support when real-only and complex-enabled paths both exist for the operator/function.
- Keep exactly one canonical `FunctionNames` and one canonical `OperatorNames` array.
- Register the new name only there with a named index (`FUNC_*` / `OP_*`).
- Elsewhere (dispatch, hints, keywords, reserved-name checks), use `FunctionNames[FUNC_*]` / `OperatorNames[OP_*]` (or wrappers) — never hardcoded name literals.
- Ensure UDFs cannot use the new builtin or new operator keyword names via those tables.

## 2) Signature hint

In `TryGetBuiltinSignatureHint`, add/update the case so hint text matches implementation (spelling/casing, fixed/variadic arity, argument meaning/optionals). Match neighboring hint formatting.
