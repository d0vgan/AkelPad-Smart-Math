# Numeric Behavior (Internal Reference)

Load when implementing, fixing, or testing numeric edge cases, NaN/Inf handling, trig snapping, aggregation accuracy, float display digit choice, or RNG detail. These rules are **agent/internal** — do **not** paste them into `USAGE_AND_SYNTAX.md` (usage-docs "Audience"). Lock them with smoke/parity tests and keep Basic/C++ parity. A brief Advanced Behavior note in USAGE is allowed only when usage-docs says so.

Accepted decisions below are already settled (raise-concerns "Already decided"). A **new** rejection or limit still goes through raise-concerns.

## Trig angle snap (`sin` / `cos` / `tan`)

Mirror `CalcSin` / `CalcCos` / `CalcTan` (Basic) and `calcSin` / `calcCos` / `calcTan` (C++):

- Snap only when the angle is a multiple of `pi/2` (and for `tan`, also `pi/4` odd multiples → `±1`) within the same residual tolerance as `IsMultipleOf` / `TryTrigHalfPiQuotient` (a few ulps of the multiple; `|k|` must fit exact-int-from-float).
- Then `sin` / `cos` return exact `0`, `±1` from `k mod 4`; `tan` returns `0` on `pi` multiples and `±inf` on odd `pi/2` multiples.
- Finite snap results `0` / `±1` stamp **SmInt** metadata (`isinstance(sin(0), int)` → `1`). Unsnapped library results and `±inf` stay float (no exact stamp).
- Do **not** snap approximate constants: `sin(1e-10)`, `sin(3.14159265359)`, `cos(1.5707963268)` stay unsnapped (near-zero or wrong-sign residual relative to true `pi`).
- Example that must snap: `cos(1e12*pi)` → `1` (float display may keep `.0`).

Python `math.sin` / `math.cos` without this snap is **not** the reference for those exact-multiple cases; the verifier stubs (`sin_sm` / `cos_sm` / `tan_sm`) must mirror the parser.

## `sign` and NaN

- Real `sign(nan)` → `nan` (not `0`). Plain compare `x < 0` / `x > 0` is wrong for NaN.
- `sign(±inf)` → `±1`. Complex `sign` stays `c/abs(c)` (coding-standards / complex-support for non-finite complex).

## Shared scalar comparison (Required)

Every scalar comparison, ordering, or equality site must go through the shared entry helpers — Basic `CmpScalarValuesForCompare` / `CmpScalarValuesForSortOrder` (and `CmpRealScalars` for real three-way), C++ `cmpScalarValuesForCompare` / `cmpRealScalars`. That includes comparison operators, `sort` / `sortby`, `unique` equality, `filter` predicates that compare, `clamp` bound checks, mixed `min` / `max` winner selection, array element compares, and compares inside user functions / lambdas. Do not reimplement float `<` / `==` at a call site.

**Real ladder** (`CmpRealScalars` / `cmpRealScalars`; neither operand NaN):

- Both sides have exact int/uint metadata → sign-magnitude integer compare
- Exact vs float (including when `|shadow| ≥ 2^53`) → `CmpSignMagnitudeWithFloat` / `cmpSignMagnitudeWithFloat` (never raw float shadows alone)
- Both float (no usable exact metadata) → float `<` / `>`
- NaN: comparison ops are unordered (`==` false, `!=` true); `sort` / `sortby` put NaN first; `unique` keeps only the first NaN
- ±Inf: normal float / sign-magnitude-with-float ordering

**Complex:** explicit `<` / `>` stay rejected. Equality and implicit ordering (`sortby`, `unique`, …) compare **per component** via the shared real compare (mixed exact-vs-float included). NaN in any Cartesian part keeps the unordered / sort-unique rules above.

**Time:** same top-level compare entry; early branch compares exact millisecond `SmInt` totals (time↔time and time↔finite/±inf; Inf may saturate). Time vs NaN uses the same NaN policy as reals (ops unordered; sort NaN-first; unique first-NaN) — never map NaN to `0` ms.

**`unique` hash:** when exact-int/uint metadata is present and `|v| ≥ 2^53` (and per exact complex component), derive the hash from sign + magnitude (mix re/im the same way as the float Cartesian mix). Keep `+0`/`-0` canonicalization and the first-NaN short-circuit. Equality confirmation still uses the shared compare.

## Exact-int promote vs false exact (Bound H)

coding-standards owns the two-tier rule (provenance preserve vs float promote). Summary for numeric tests:

- **Bound H:** `B = 2^min(⌊mant/2⌋, intBits−1)` → baseline `2^26`. Only `makeScalarMaybeExact` / `ValueSetScalarMaybeExact` may promote a **computed** float to exact.
- **May promote under H:** `1.5+1.5` → exact `3`; named trig snaps `0`/`±1`; small integer-valued float-op results with `|v| < B`.
- **Must stay float (no exact metadata):** large integer-looking float products near mantissa loss, e.g. `(2**51-8)*((5/2)+1e-12)`; any float-op result with `|v| ≥ B` even if `v == trunc(v)`; non-integer input decimals (`1.5`).
- **Provenance still exact at full SmInt/SmUInt range:** `1+1`, `sqrt(81)`, `hypot(3,4)`, all-exact `sum(1,2)`, `floor(1.7)`, digit-exact literals (`1`, `1.0`, `67108864.0`, `0.123e4`), and verified reconstruct including large unsigned bases (`pow(2**62,1/2)`, `pow((2**32-1)**2,1/2)`) — Bound H does not apply to that stamp. Non-perfect large roots stay float (`pow(2**63,1/2)`).

## Aggregates: `sum`, `avg`/`mean`, `median`, `unique`, compares/sorts

- **`sum` / `product`:** all-exact-int folds keep exact metadata. Floating finishes use MaybeExact (Bound H; Neumaier for sum) so `sum(1.5,1.5)` matches `1.5+1.5` under H. Compensated example: `sum(1e100, 1, -1e100)` → `1`; `sum(0.1, 0.2, 0.3)` → `0.6`.
- **`avg` / `mean`:** integer inputs are summed and divided exactly when divisible (`avg(9007199254740993, 9007199254740995)` → `9007199254740994`). Non-divisible exact-sum quotient and float finishes use MaybeExact.
- **`median`:** any input `nan` → `nan`. When **every** arg has exact-int metadata, sort/midpoint on exact integers (not only large-mag cases): odd count keeps the middle item's metadata; even count with an integer midpoint stays exact (`median(1,3)` → `2`); a non-integer midpoint uses MaybeExact (`median(1,2)` → `1.5` float). Mixed/non-exact args use the float path with MaybeExact. Even count float form stays overflow-safe (`0.5*lo + 0.5*hi`), so `median(1e308, 1.5e308)` → `1.25e+308` and `median(-1e308, 1e308)` → `0`.
- **`variance` / `stddev`:** always plain float (no MaybeExact).
- **`hypot`:** when both legs have exact-int metadata, a zero leg returns `|other|` with metadata; otherwise sum-of-squares then the same perfect-square verify as `sqrt` (`hypot(3,4)` → exact `5`). Non-perfect / float fallback uses MaybeExact (Bound H).
- **`unique` / `sort` / compares / `clamp` / mixed `min`/`max`:** follow "Shared scalar comparison" above. Distinct exact integers above `2^53` (and SmUInt range) stay distinct and order by true integer value. `unique` keeps only the first NaN; later `nan` / `-nan` drop (USAGE Advanced Behavior may mention NaN uniqueness briefly; full exact-int rule stays here).
- Empty remaining values → `()` (empty-array-policy).

## Float display digits

- Prefer the shortest decimal that round-trips (often 15 significant digits); use 16 when 15 is not enough. Large binary64 magnitudes keep scientific form (`1e23` → `1e+023`).
- C++ / Basic / plugin formatter differences that remain intentional are listed in the parity skill (ties, `±2^53` display). Do not document digit heuristics in USAGE function sections.

## Random

- `rand` / `random` are seeded from the clock at start-up.
- C++ draws a full floating-point mantissa per call; keep Basic/C++ statistical contract (`random(a,a)` → `a`, range half-open) without putting RNG implementation text in USAGE.

## Where else this lives

| Concern | Also see |
|---|---|
| Exact-int provenance / Bound H / `MAX_MAGNITUDE` | coding-standards "Integer metadata preservation" |
| Shared compare / unique hash helper reuse | coding-standards "Helper reuse and optimization" |
| Non-finite accept/reject for a **new** path | coding-standards "Non-finite values" + raise-concerns |
| Empty `()` aggregates | empty-array-policy |
| Test expectations / Python verifier stubs | smoke-tests; `tools/verify_smoke_expected_vs_python.py` |
| End-user wording | usage-docs "Audience" |
