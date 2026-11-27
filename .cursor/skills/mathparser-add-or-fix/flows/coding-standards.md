# Coding Standards (Parser Implementation)

Load when writing or editing Basic/C++ parser implementation (skip for docs-only or gate-only work). This file is the single home for the rules below; other flows link here instead of restating them.

## Helper reuse and optimization

- Search for an existing helper that covers or nearly covers the need before adding one.
- User-function and lambda body, parameter, and definition rules already share one helper per rule (user-functions-and-lambdas flow). Extend that helper. Do not add a second copy for the other surface.
- **Comparison / equality / ordering / dedupe:** every scalar compare path (operators, `sort` / `sortby`, `unique` equality, `clamp`, mixed `min`/`max`, array element compares) must call the shared compare helpers (`CmpScalarValuesForCompare` / `cmpScalarValuesForCompare`, `CmpRealScalars` / `cmpRealScalars`, and the sort-order variant). Do not reimplement float `<` / `==` for scalars. `unique` hashing follows numeric-behavior (exact-int keys when metadata is present at/above `2^53`).
- If close: extend it and migrate old and new call sites; keep it hot-path efficient.
- Otherwise add a **narrow** new helper (no overlapping responsibilities).
- Reuse existing locals/state before adding temporaries.
- Keep project indentation and clean nested blocks.

## C++ class shape

C++ helper placement follows `.cursor/skills/mathparser-add-or-fix/flows/cpp-class-design.md`: a `MathParser` method only when it reads or writes session state. Basic stays procedural; do not restructure `MathParser.bas` to match C++ types.

## Non-finite values

For a new operator or builtin, or a touched path whose behavior changes: whether `inf` / `-inf` / `nan` are accepted or rejected is a raise-concerns decision (standard math and typical calculator behavior). After the user decides, keep Basic/C++ parity and lock the decision with tests (including error text when rejecting). Settled per-function NaN rules (e.g. `sign(nan)`, `median` with any `nan`) and related numeric edge behavior live in `numeric-behavior.md` — do not expand them into `USAGE_AND_SYNTAX.md` function bullets (usage-docs "Audience").

## Undefined behavior

No UB in C++ or Basic. Reuse the existing helpers below instead of writing new checks:

| Need | C++ | Basic |
|---|---|---|
| Signed overflow checked **before** the operation (never by inspecting a wrapped result) | `tryAddSmIntChecked`, `trySubSmIntChecked`, `tryMulSmIntChecked` | `TryAddSmUIntChecked`, `TryMulSmUIntChecked` (unsigned) |
| Sign-magnitude form, so the most negative `SmInt` is never negated as a signed value | `uintMagnitudeOfSmInt`, `smIntFromNegatedMagnitude`, `tryGetExactSignMagnitudeFromScalar`, `makeScalarFromSignMagnitude` | `uintMagnitudeOfSmInt`, `TryGetExactSignMagnitudeScalar`, `ValueSetFromSignMagnitude` |
| Double → integer with a range check first | `tryRoundFloatToSmInt`, `tryRoundFloatToSmUInt`, `tryRoundHalfUpFloatToSmInt` | `TryRoundHalfUpFloatToSmInt` |

Range-check every double before converting it to an integer: C++ casts out of range are UB, and FreeBASIC `Int` / `CLngInt` wrap through `LongInt` for magnitudes `>= 2^63`.

## Numeric types and limits (Required)

The parser is retargetable: only `SmFloat`, `SmInt` and `SmUInt` name the numeric types (C++ `smartmath::SmFloat/SmInt/SmUInt`, Basic `SmFloat/SmInt/SmUInt`), and every limit, bound, tolerance and table derived from them lives in one file per language: `cpp/MathParserTypes.hpp` and `Inc/MathParserTypes.bi` (`kIntMax`/`SM_INT_MAX`, `kFloatSmIntBound`/`SM_FLOAT_SMINT_BOUND`, `kMaxExactIntFromFloat`/`SM_MAX_EXACT_INT_FROM_FLOAT`, `kMaxExactIntFromFloatOp`/`SM_MAX_EXACT_INT_FROM_FLOAT_OP`, `kTolLost*`/`SM_TOL_LOST*`, `pow10SmUInt`, `factorialInt`, the range helpers, ...).

- Never write `double`, `long long`, `int64_t`, `Double`, `LongInt`, `ULongInt`, `9223372036854775807`, `2^53`-style literals or `1ull << n` in parser code; use the types and the derived names above. Add a new derived limit to the type file, with a baseline `static_assert` / `SM_STATIC_ASSERT` that pins the default value.
- Name functions, constants and enumerators after the types they handle: `SmInt` / `SmUInt` (`tryMulSmIntChecked`, `kFloatSmIntBound`, `SM_FLOAT_SMINT_BOUND`, `RSK_SMINT`), never `SInt` / `UInt` or a width such as `Int64` / `UInt64`. Struct fields, accessors and locals (`exactInt`, `hasUInt`) and the `kInt*` / `kUInt*` / `SM_INT_*` / `SM_UINT_*` limit constants keep their short names.
- The float-to-integer range checks use the exclusive bounds (`isFloatInSmIntRange`, `isFloatInSmUIntRange`); never compare against `double(LLONG_MAX)` (that value rounds up to `2^63`).
- Code that must stay bound to a width (the binary64 `ddMulExact`, the 64-bit factorint algorithm, the libc extern block, binary64 test helpers) is wrapped in `SM_FIXED_WIDTH_BEGIN` / `SM_FIXED_WIDTH_END` (or a trailing `SM_FIXED_WIDTH`) and explains why.
- Width-generic code must compile without warnings for every type choice. A condition that folds to a constant in one configuration (C6326 "Potential comparison of a constant with another constant", C4127) is fixed, not suppressed: in tests use `widthgeneric::same()` / `greater()`, in parser code a `static_assert`, a template overload or tag dispatch (C++14), in Basic `SM_STATIC_ASSERT` / `#if`. See build-gates "Warnings".
- Tests that expect 64-bit / binary64 text are built only when `SMARTMATH_BASELINE_WIDTHS` (C++) / `SM_BASELINE_WIDTHS` (Basic) is set; width-generic expectations are derived by decimal-string arithmetic from the type widths (`widthgeneric` in `Tests_MathParser.cpp`, `tests/WidthGenericDecimal.bi`), never from the parser output or its own tables.
- `tools/check_type_literals.ps1 -Strict` must report zero hits outside the type files and the marked fixed-width regions.

## Integer metadata preservation (Required)

Two tiers — do not conflate them:

1. **Provenance preserve** — exact-int inputs + integer-nature ops (checked SmInt/SmUInt `+−*/`, verified int×float promote / **pow·√·hypot reconstruct**, exact median/avg when divisible, trig/exp/ln named snaps, rounding builtins, bitwise, counts, and **digit-exact numeric literals**) keep exact metadata at full `SmInt`/`SmUInt` range via `makeScalarInt` / `ValueSetSmInt` (and uint peers). Do **not** route these through MaybeExact.
2. **Float-result promote (Bound H)** — a bare **computed** `SmFloat` (operation/function result, not a digit-exact literal) may gain exact metadata **only** through the single helper pair `makeScalarMaybeExact` / `ValueSetScalarMaybeExact` (and their shared extract `tryExtractExactSmIntFromFloatForPromote` / `TryGetExactSmIntFromFloatForPromote`). Promote when finite, integer-valued (`v == trunc(v)`), and `|v| < B` with  
   `B = 2^min(⌊p/2⌋, n−1)` where `p` = float mantissa digits and `n` = `SmInt` bits.  
   Code names: Basic `SM_MAX_EXACT_INT_FROM_FLOAT_OP`; C++ `smartmath::kMaxExactIntFromFloatOp` (baseline binary64+int64 → `2^26`). No call-site `|v| < B` checks; no second looser “restore up to full mantissa for ops” API.

`MAX_MAGNITUDE` = `2^mantissa` (baseline `2^53`): largest magnitude at which every integer is an exact float bit-pattern. Code names: Basic `SM_MAX_EXACT_INT_FROM_FLOAT`; C++ `smartmath::kMaxExactIntFromFloat`. Use the **Strict** extract (`TryGetExactSmIntFromFloat` / `tryExtractExactSmIntFromFloat`) only for **non-promote** questions (metadata↔shadow consistency, FactorInt gates, “is this float an exact integer within full exact-int-from-float range?”). Never as a parallel promote-to-exact path — sites that stamp exact from a float use MaybeExact (Bound H).

Exact signed/unsigned metadata (`exactInt` / `exactUInt` or equivalents) is first-class in Basic and C++:

| Where the integer comes from | exact-int | exact-uint |
|---|---|---|
| **Preserved (provenance):** integer op / verified reconstruct / intentional round-to-int / digit-exact literal / already-valid metadata | `SmInt` min…max | `0`…`SmUInt` max |
| **Promoted from a computed float (Bound H via MaybeExact only)** | exclusive `|v| < B` | nonnegative subset of that range |
| **Strict float identity (non-promote)** | within `MAX_MAGNITUDE` | within `MAX_MAGNITUDE` |

Rules:

- Never drop valid provenance metadata, including structure-only transforms (flatten, reshape, sort, reverse, dedupe, format, unpack). Prefer metadata-carrying scalar walkers over raw `double` buffers.
- Never promote a computed float with `|v| ≥ B` (Bound H), even when it is integer-valued within `MAX_MAGNITUDE` — false-exact risk from lost low bits (e.g. near `2^51`).
- Never round a non-integer into an integer, and never use a tolerance helper (such as `nearlyInt`) to stamp exact metadata.
- **Literals (input, digit-exact):** the written form is exact. Integer tokens (`1`, `1e2`) and decimals whose fractional digits are all zero after applying a decimal exponent (`1.0`, `2.00`, `1.0e3`, `0.123e4`) stamp full-range exact metadata from digit arithmetic — **not** Bound H / MaybeExact. A non-zero written fraction (`1.5`, `1.0e-1`) stays plain float. Do not demote `67108864.0` (or larger digit-exact forms that fit `SmUInt`) just because `|v| ≥ B`.
- **Verified pow / √ / hypot reconstruct:** float is only a candidate guess; stamp only after checked `SmUInt`/`SmInt` power (or `n*n`) matches the **exact** base. Signed float-assisted ByKind is mag-gated to `|base| < MAX_MAGNITUDE` (`2^mantissa`) so the float shadow holds the base. **Unsigned** ByKind is **not** mag-gated: large exact nonnegative bases (`|v| ≥ MAX_MAGNITUDE`) still try SmUInt reconstruct (`pow(2**62,1/2)`). That is provenance, not Bound H — do not confuse the `2^53` signed gate with Bound H `B`. A wrong float guess fails verify (missed exact), it does not false-stamp.
- **Aggregates:** float `sum` / `product` / `avg`/`mean` / `median` finishes use MaybeExact (Bound H), same as binary `+` — so `sum(1.5,1.5)` matches `1.5+1.5` when the float result is integer-valued under H. All-exact-int folds keep provenance. Non-divisible exact-sum avg / even median midpoints that are float also go through MaybeExact. `variance`/`stddev` stay plain float.
- **Complex / ratio:** Cartesian `FromFloats` / float-restore and ratio near-int stamp via MaybeExact (not Strict→`makeScalarInt`).
- Transcendental bodies call MaybeExact once on the float result; named snaps `0`/`±1` may use provenance `makeScalarInt` or MaybeExact (equivalent under H).
- Rounding builtins (`floor`/`ceil`/`round`/`trunc`/`int`) keep provenance stamps — intentional round-to-int.
- Applies when adding a builtin/operator or intentionally changing numeric behavior. A behavior-preserving cleanup keeps the metadata behavior it found.
- Keep Basic/C++ boundaries and errors aligned; lock display kind (`RSK_SMINT` vs floating) with tests where affected.
- **Signed `*` SmUInt promote:** when checked SmInt mul fails, try the sign-magnitude product into SmUInt (covers `INT_MIN*(-1)`, neg×neg → `2^63`, and both-nonneg above `INT_MAX`). Negative products promote only when they still fit SmInt (incl. `INT_MIN`). Keep `/`'s `INT_MIN/-1` path; `0-(-INT_MIN)` / `INT_MAX-(-1)` promote via checked add of magnitudes into SmUInt like unary `-INT_MIN`.

## Comments (ASCII only)

Comments in parser source (`MathParser.bas`, included Basic modules, `cpp/MathParser*.hpp` / `.cpp`, and related implementation files) must be ASCII only. Do not put Unicode in comments (no en/em dashes, smart quotes, arrows, math symbols such as `×` / `≤` / `√`, non-Latin letters). If newly written or edited comments contain Unicode, replace each character with an ASCII equivalent (`-`, `->`, `"`, `*`, `<=`, `sqrt`, plain Latin transliteration, etc.) before finishing the edit.

## String constants naming

- String literals longer than one character → named constant; one-character literals may stay inline.
- Reuse an existing constant for the same literal.
- Names are semantic (`STR_*` in C++, `FB_STR_*` in Basic); no opaque `STR_0001` names.
