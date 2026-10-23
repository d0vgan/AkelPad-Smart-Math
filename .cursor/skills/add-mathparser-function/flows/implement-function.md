# Implement Builtin Function

Load when adding or changing a **builtin function** (or an operator path that uses the same registration pattern).

## Required follow-on reads (do not skip for a new/changed function)

| Phase | Path |
|---|---|
| Before coding parser logic | `.cursor/skills/add-mathparser-function/flows/coding-standards.md` |
| C++ parser files will change | `.cursor/skills/add-mathparser-function/flows/cpp-class-design.md` |
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

## 3) Implement in C++

Mirror behavior, error text, and exact-int metadata. Do not mirror Basic’s procedure layout onto `MathParser`.

Follow cpp-class-design:

- One `BuiltinFunctionId`, one `kBuiltinMeta` row, one `FunctionNames` entry.
- Scalar math as a file-local function or on `ScalarValue` / `smartmath_internal`.
- Route through the existing family handler when the category exists (`builtinUnaryMath`, `builtinAggregateFamily`, `builtinScalarBinaryFamily`, and the other family routers).
- Reuse `ParseErrorId`. Do not add `setFooError` or `MathParser::builtin…` unless the handler must read session state and no family router can host the call. That method stays a thin forwarder.
- Hints and reserved-name checks read the same name tables as Basic. No extra name literals.
