# Complex Number Support And Real/Complex Parity

Load when the task mentions complex numbers, the parser-wide complex support flag, Cartesian builtins, or changes that touch real-only and complex-enabled operator/function paths.

## Parser-wide option

Global switch: Basic `Parser_SetSupportComplexNumbers` / `Parser_GetSupportComplexNumbers`; C++ `MathParser::setSupportComplexNumbers` / `getSupportComplexNumbers`.

- **Default off:** with the switch off, keep historical real-only semantics (non-real domains → `NaN` or errors as today). Do not change default-off behavior unless the task explicitly extends complex support.
- **When on:** complex parsing, ops, builtins, and array/scalar rules may activate. Every path that produces or consumes complex values must consult the flag (or a thin helper over it) so real-only users never see semantic surprises.
- **Scalars and arrays:** with the switch on, builtins should accept one complex scalar or an array of complex values per argument, consistent with existing scalar/array conventions.
- **Tests (strict separation):** do not put complex-domain expectations in the main `SmokeCase` table in `SmokeTest_MathParser.bas`. Put them only in **`RunComplexNumberSupportOptionTests()`** (or a dedicated sub) and **enable** `Parser_SetSupportComplexNumbers(TRUE)` at the start of that routine. C++: add cases only in **`buildComplexNumberSupportOptionCases()`**, run via `runSuite("Complex number support (parser option)", ...)`. Each case that needs complex mode calls `setSupportComplexNumbers(true)` at the start of its own lambda. Do not add a suite-level setup. Restore/assert flag off at end of the Basic routine when needed so other suites stay isolated.
- **Parity:** flag effects on parse/eval must be mirrored Basic ↔ C++ with tests in those dedicated areas.
- **Exact int metadata:** with complex on, use the coding-standards exact-int section for **both** Cartesian parts (`MAX_MAGNITUDE`). Do not restate that section’s ranges here. Keep Basic/C++ construction, binary ops, and display paths consistent.
- **Tiny-nonzero:** for `real` / `imag` / `conj` (and similar Cartesian extraction), do not snap tiny nonzero doubles to integer `0`. If the reference is nonzero (e.g. `imag(1.123e+20+1.123e-20*i)`), expectations must keep that nonzero (often scientific notation), not `0`.

## Real ↔ complex operator/function parity (Required)

Treat real-only and complex-enabled behavior as one design surface for operators, builtins, and shared helpers. Apply both directions unless semantics truly differ (document why in code/tests).

### Real → complex

- Fixes/policies/helpers on a **real-only** path (for example `ApplySqrtScalarValue`, exact-int verification after `sqr`, float vs int64 export rules, non-finite handling) must be reused or mirrored on the **complex** path when complex mode can hit the same case.
- Prefer **one shared helper** (e.g. negative real `sqrt` uses the same magnitude/`sqrt` policy as `sqrt(|x|)`, not a divergent `sqr(-x)` shortcut with different exactness rules).
- Complex-only wrappers (Cartesian multiply, `ValueSetScalarComplexFromDoubles`, pure-imaginary constructors) must not weaken rules the real path already enforces.

### Complex → real

- Fixes on a **complex** path must be checked on the **real-only** path for purely real operands (imag = 0).
- Do not leave real-only code on an older divergent branch after complex work set the canonical behavior.
- Where parity matters, update dedicated complex suites **and** main smoke cases for purely real inputs of the same shape.

### Before finishing

- Name the **real dispatch** and **complex dispatch** (if any); shared helpers or documented intentional asymmetry.
- Exact int64 on one side and float on the other for the same numeric situation is a bug unless tests lock different semantics. A component whose magnitude is greater than `MAX_MAGNITUDE` (coding-standards) is not that situation: do not promote the double so the sides match.
- Mirror display-kind expectations (`RSK_INT64` vs `RSK_FLOATING`) in Basic, C++, and formatter/raw-export tests when affected.
