# Implement Builtin Constant (Reserved Names)

Load when introducing a new identifier parsed as a **constant** (like `pi` / `e`), not a function call.

## Required follow-on reads (do not skip for a new constant)

| Phase | Path |
|---|---|
| Before coding | `.cursor/skills/add-mathparser-function/flows/coding-standards.md` |
| Mirroring to C++ (when `cpp/MathParser.cpp` exists) | `.cursor/skills/internal-mathparser-basic-cpp-parity/SKILL.md` |
| After registration — **tests** | `.cursor/skills/add-mathparser-function/flows/smoke-tests.md` |
| After registration — **docs** | `.cursor/skills/add-mathparser-function/flows/usage-docs.md` |
| Before finishing — **gates** | `.cursor/skills/internal-mathparser-build-gates/SKILL.md` |

## Canonical table in `MathParser.bas`

Same pattern as `FunctionNames`:

- **`BuiltinConstId`** — `CONST_*` enum + sentinel `CONST__COUNT`
- **`ConstNames(0 to CONST__COUNT - 1)`** — lowercase spellings in **`EnsureConstNames()`** (e.g. `ConstNames(CONST_PI) = "pi"`)
- **`TryGetConstant`** — resolve via `TryFindBuiltinConstId` / `ConstNames`, then `select case` on id for the value
- **`IsBuiltinConstantName`** — true when `TryFindBuiltinConstId` finds an index (assignment / UDF name / parameter reserved checks)

When adding: extend the enum, one line in `EnsureConstNames`, one `case` in `TryGetConstant`. Never register the spelling only in `TryGetConstant` — reserved-name checks would miss it.

## Reserved-name call sites

After updating the table:

- Assignment / binding errors should already go through `IsBuiltinConstantName` (search call sites if new binding forms appear).
- Do not add a second hardcoded constant-name list; `EnsureConstNames` is the single string source.

## C++ parity (`cpp/MathParser.cpp`)

When `cpp/MathParser.cpp` exists:

- Register the same identifier and value semantics (e.g. `addConst`).
- Extend any C++ reserved-name checks for assignments/UDFs to match Basic `IsBuiltinConstantName`.

## Constant-specific tests

Follow smoke-tests flow for expectation rules. Mirror `pi` / `e` coverage:

- Assignment LHS rejected (`expectedErrContains` matching `reserved constant name`)
- Case-insensitive variant if resolution is case-insensitive
- UDF parameter name and UDF function name rejected when equal to the new constant

## Docs

Follow usage-docs flow (constant section): list the new constant everywhere `pi` / `e` appear for builtins and reserved names — not in only one section.
